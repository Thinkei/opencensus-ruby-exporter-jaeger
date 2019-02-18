require 'parser/current'
require 'byebug'
require 'fileutils'

class CollectorRewrite < Parser::Rewriter
  def on_class(node)
    klass = node.children.first
    range = Parser::Source::Range.new(
      klass.loc.expression,
      klass.loc.expression.begin_pos,
      klass.loc.expression.end_pos
    )
    replace(range, klass.children.last.to_s)

    range = Parser::Source::Range.new(
      node.loc.expression,
      node.loc.expression.begin_pos,
      node.loc.expression.end_pos
    )

    wrap(range, "module ::EhMonitoring::Collectors\n", "\nend")
  end
end

class CollectorMigration < Parser::Rewriter
  def on_const(node)
    if node.children.last.to_s =~ /.*Collector$/ && node.children[-2].to_s != ~ /Collectors/
      range = Parser::Source::Range.new(
        node.loc.expression,
        node.loc.expression.begin_pos,
        node.loc.expression.end_pos
      )
      replace(range, "EhMonitoring::Collectors::#{node.children.last}")
    end
  end

  def on_send(node)
    if node.children[1] == :require
      file = node.children.last
      file_link = file.children.first
      if file_link =~ /collector$/ && file_link != ~ /collectors/
        range = Parser::Source::Range.new(
          file.loc.expression,
          file.loc.expression.begin_pos,
          file.loc.expression.end_pos
        )
        files = file_link.split "/"
        replace(range, "\"#{files.insert(files.length - 1, "collectors").join("/")}\"")
      end
    elsif node.children[2]&.type == :const
      on_const(node.children[2])
    end
  end
end

FileUtils.mkdir_p("lib/eh_monitoring/collectors")
FileUtils.mkdir_p("spec/units/eh_monitoring/collectors")

Dir["lib/**/*_collector.rb"].each do |file|
  buffer = Parser::Source::Buffer.new("(Migration)")
  buffer.source = File.read(file)
  ast = Parser::CurrentRuby.new.parse(buffer)
  rewriter = CollectorRewrite.new
  content = rewriter.rewrite(buffer, ast)
  lines = content.split("\n")
  lines.each_with_index do |line, index|
    next if index == 0 || index == lines.length - 1
    lines[index] = "  #{line}"
  end
  content = lines.join("\n")
  File.write("lib/eh_monitoring/collectors/#{file.split("/").last}", content)
  File.delete(file)
end

Dir["spec/units/eh_monitoring/*_collector_spec.rb"].each do |file|
  File.write("spec/units/eh_monitoring/collectors/#{file.split("/").last}", File.read(file))
  File.delete(file)
end

file = "spec/units/eh_monitoring/instance_spec.rb"
Dir["**/*.rb"].each do |file|
  buffer = Parser::Source::Buffer.new("(Migration)")
  buffer.source = File.read(file)
  ast = Parser::CurrentRuby.new.parse(buffer)
  rewriter = CollectorMigration.new
  content = rewriter.rewrite(buffer, ast)
  File.write(file, content)
end

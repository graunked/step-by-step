require 'rugged'
require 'github/markdown'
require 'cgi'
require 'pry'

(file, firstCommit) = ARGV

repo = Rugged::Repository.new('.')
walker = Rugged::Walker.new(repo)
walker.sorting Rugged::SORT_REVERSE
walker.push repo.head.target

commits = walker.to_a 
firstIndex = commits.index{|c| (firstCommit == c.oid[0..firstCommit.length-1])} - 1

commits = commits.drop(firstIndex)

pairs = ([nil] + commits).zip(commits + [nil])[2...-1]

diffs = pairs.map do |first, second| 
  result   = `git diff -U9999999 #{first.oid} #{second.oid}`.lines.drop(6)
  result = result.map {|line| [line[0], line[1...line.length]]}
  result = result.map do |first, rest| 
    if first == '+'
      type = :new
    elsif first == '-'
      type = :removed
    elsif first == ' '
      type = :old
    end
    [type, rest]
  end
end


Dir.mkdir('versions')

puts "<link rel='stylesheet' href='step-by-step.css' />"

commits.drop(2).zip(diffs).drop(firstIndex).each do |commit, diff|
  puts "<div class='explanation'>"
  puts GitHub::Markdown.render_gfm commit.message
  puts "</div>"
  puts "<div class='version'>"
  puts "<div class='code'>"
  diff.each do |type, line|
    puts "<pre class='#{type.to_s}'>", CGI::escapeHTML(line), "</pre>"
  end 
  puts "</div>"
  filename = "versions/#{commit.oid[0..5]}.html"
  File.open(filename, 'w'){|f| f.write( `git show #{commit.oid}:#{file}` ) }
  puts "<iframe src='#{filename}'>"
  puts '</iframe>'
  puts '<div style="clear: both"></div>'
  puts "</div>" 
end

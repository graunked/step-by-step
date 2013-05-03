require 'rugged'
require 'github/markdown'

(file, firstCommit) = ARGV

repo = Rugged::Repository.new('.')
walker = Rugged::Walker.new(repo)
walker.sorting Rugged::SORT_REVERSE
walker.push repo.head.target

commits = walker.to_a 
firstIndex = commits.index {|c| firstCommit == c.oid[0..firstCommit.length-1]}

puts "<script src='jquery-1.8.0.js'></script>"
puts "<script src='diff_match_patch.js'></script>"
puts "<script src='blog.js'></script>"
puts "<link rel='stylesheet' href='step-by-step.css' />"

commits.drop(firstIndex).each do |commit|
  puts "<div class='explanation'>"
  puts GitHub::Markdown.render_gfm commit.message
  puts "</div>"
  puts "<div class='code'><pre class='input'><code>" 
  puts `git show #{commit.oid}:#{file}`
  puts "</div></pre></code>" 
end

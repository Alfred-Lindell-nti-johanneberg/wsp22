require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
    slim(:firstpage)
end

get('/pictures') do
    db = SQLite3::Database.new("db/Birdwatch_forum.db")
    db.results_as_hash = true
    posts = db.execute("SELECT * FROM posts WHERE topic_id = 1")
    puts posts
    slim(:pictures, locals:{posts:posts})

end
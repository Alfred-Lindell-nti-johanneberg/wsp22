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

get('/addpost') do
    slim(:addPost)
end

post('/postmade') do
    @id = 1 #add session för inloggad user id
    title = params[:title]
    body=params[:body]
    p params[:topic]
    topic = params[:topic].to_i

    db = SQLite3::Database.new("db/Birdwatch_forum.db")
    db.execute("INSERT INTO posts (title, body, user_id, topic_id) VALUES (?, ?, ?, ?)",title,body,@id,topic)
    redirect("/addpost")    
end

get('/deletePost') do
    slim(:deletePost)

end

post('/postdeleted') do
    db = SQLite3::Database.new("db/Birdwatch_forum.db")
    title = params[:title]
    db.execute("DELETE FROM posts WHERE title = ?",title)

    redirect("/deletePost")
end
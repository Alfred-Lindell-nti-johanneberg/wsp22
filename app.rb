require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions


get('/') do
    session[:id]=1
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
    slim(:'posts/addPost')
end

post('/postmade') do
    @id = session[:id] #add session för inloggad user id
    title = params[:title]
    body=params[:body]
    p params[:topic]
    topic = params[:topic].to_i

    db = SQLite3::Database.new("db/Birdwatch_forum.db")
    db.execute("INSERT INTO posts (title, body, user_id, topic_id) VALUES (?, ?, ?, ?)",title,body,@id,topic)
    redirect("/addpost")    
end

get('/deletePost') do
    slim(:'(posts/deletePost')

end

post('/postdeleted') do
    db = SQLite3::Database.new("db/Birdwatch_forum.db")
    title = params[:title]
    db.execute("DELETE FROM posts WHERE title = ?",title)

    redirect("/deletePost")
end

get('/register') do
    id=session[:id]
    slim(:'users/new', locals:{key:(id)})

end

post('/users/new') do
    username = params[:username]
    email = params[:email]
    password = params[:password]
    password_confirm = params[:password_confirm]
  
    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('db/todo_login_sida.db')
      db.execute("INSERT INTO users (username,pwdigest,email) VALUES (?,?)",username,password_digest,email)
      redirect('/')
    else
      #felhantering
      "Lösenorden matchade inte"
    end
end
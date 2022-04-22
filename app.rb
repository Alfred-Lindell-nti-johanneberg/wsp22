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
    users = db.execute("SELECT * FROM users")
    puts posts
    puts users
    slim(:pictures, locals:{posts:posts,users:users})

end
get('/spots') do
    db = SQLite3::Database.new("db/Birdwatch_forum.db")
    db.results_as_hash = true
    posts = db.execute("SELECT * FROM posts WHERE topic_id = 2")
    users = db.execute("SELECT * FROM users")
    slim(:spots, locals:{posts:posts,users:users})

end
get('/bogos') do
    db = SQLite3::Database.new("db/Birdwatch_forum.db")
    db.results_as_hash = true
    posts = db.execute("SELECT * FROM posts WHERE topic_id = 3")
    users = db.execute("SELECT * FROM users")
    slim(:bogos, locals:{posts:posts,users:users})

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
      db = SQLite3::Database.new("db/Birdwatch_forum.db")
      db.execute("INSERT INTO users (name,role_id,pwdigest,email) VALUES (?,?,?,?)",username,nil,password_digest,email)
      redirect('/')
    else
      #felhantering
      "Lösenorden matchade inte"
    end
end

get('/logout') do
    session.destroy
    redirect('/')
end

get('/login') do
    slim(:'users/login')
end

post('users/login') do
    username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/Birdwatch_forum.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE name = ?",username).first
  pwdigest = result["pwdigest"]
  id = result["id"]

  if BCrypt::Password.new(pwdigest) == password
    session[:id]= id
    redirect('/')
  else
    "Fel lösen, din skojare"
  end
end
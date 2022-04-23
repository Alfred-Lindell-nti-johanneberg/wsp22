require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions


def connect_to_db()
    db = SQLite3::Database.new("db/Birdwatch_forum.db")
end



get('/') do
    slim(:index)
end

get('/quick_admin_login') do
    session[:id]= 1
    session[:username] = "Admin"
    redirect('/')
end

get('/pictures') do
    db = connect_to_db()
    topic_id=1
    db.results_as_hash = true
    posts = db.execute("SELECT * FROM posts WHERE topic_id = ?",topic_id)
    users = db.execute("SELECT * FROM users")
    puts posts
    puts users
    slim(:'posts/index_pictures', locals:{posts:posts,users:users})

end
get('/spots') do
    db = connect_to_db()
    db.results_as_hash = true
    posts = db.execute("SELECT * FROM posts WHERE topic_id = 2")
    users = db.execute("SELECT * FROM users")
    slim(:'posts/index_spots', locals:{posts:posts,users:users})

end
get('/bogos') do
    db = connect_to_db()
    db.results_as_hash = true
    posts = db.execute("SELECT * FROM posts WHERE topic_id = 3")
    users = db.execute("SELECT * FROM users")
    slim(:'posts/index_bogos', locals:{posts:posts,users:users})

end

get('/posts/new') do
    slim(:'posts/new')
end

post('/post/create') do
    id = session[:id] 
    title = params[:title]
    body=params[:body]
    p params[:topic]
    topic = params[:topic].to_i

    db = connect_to_db()
    db.execute("INSERT INTO posts (title, body, user_id, topic_id) VALUES (?, ?, ?, ?)",title,body,id,topic)
    redirect("/posts/new")    
end

get('/users/:id') do
    id = session[:id]
    db=connect_to_db()
    db.results_as_hash = true
    posts = db.execute("SELECT * FROM posts WHERE user_id = ?",id)
    slim(:'users/show', locals:{posts:posts})
end

post('/postdeleted') do
    db = connect_to_db()
    post_id = params[:id]
    post_user_id = db.execute("SELECT user_id FROM posts where id = ?",post_id)
    session[:delpostattempt]=0
    if post_user_id != []
        if session[:id]==post_user_id[0][0]       
            db.execute("DELETE FROM posts WHERE id = ?",post_id)
            session[:delpostattempt]=nil
        else
            session[:delpostattempt]+=1
        end
    else
        session[:delpostattempt]+=1
    end
    redirect("/users/:id")
end

get('/register') do   
    slim(:'users/new')
end

post('/users/new') do
    username = params[:username]
    email = params[:email]
    password = params[:password]
    password_confirm = params[:password_confirm]

    session[:regattempt]=0

    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = connect_to_db()
      db.execute("INSERT INTO users (name,role_id,pwdigest,email) VALUES (?,?,?,?)",username,nil,password_digest,email)
      session[:regattempt]=nil
      redirect('/')
    else
      session[:regattempt]+=1
      redirect('/register')
    end
end

get('/logout') do
    session.destroy
    redirect('/')
end

get('/login') do
    slim(:'users/login')
end

post('/user/login') do
    username = params[:username]
  password = params[:password]
  db = connect_to_db()
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE name = ?",username).first
  session[:loginattempt]=0
  if result==nil 
    session[:loginattempt] +=1
    redirect('/login')
  end

  pwdigest = result["pwdigest"]
  id = result["id"]

  if BCrypt::Password.new(pwdigest) == password
    session[:id]= id
    session[:username] = username
    session[:loginattempt] = nil
    redirect('/')
  else
    session[:loginattempt] +=1
    redirect('/login')
  end
end
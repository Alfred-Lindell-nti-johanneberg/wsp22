require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions


def connect_to_db()
    db = SQLite3::Database.new("db/Birdwatch_forum.db")
end



get('/') do
    p session[:id]
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
    if session[:id] == nil
        current_user = nil
    else
        current_user= db.execute("SELECT role_id FROM users WHERE id = ?",session[:id]).first
    end

    slim(:'posts/index_pictures', locals:{posts:posts,users:users, current_user:current_user})

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

get('/posts/:id') do
    id = params[:id]
    db = connect_to_db()
    db.results_as_hash = true
    post = db.execute("SELECT * FROM posts WHERE id = ?",id).first
    user = db.execute("SELECT * FROM posts INNER JOIN users ON users.id = posts.user_id WHERE posts.id = ? ",id).first
    slim(:'posts/show', locals:{post:post,user:user})
end

post('/posts/create') do
    id = session[:id] 
    title = params[:title]
    body=params[:body]
    p params[:topic]
    topic = params[:topic].to_i
    db = connect_to_db()
    db.execute("INSERT INTO posts (title, body, user_id, topic_id) VALUES (?, ?, ?, ?)",title,body,id,topic)
    redirect("/posts/new")    
end

post('/post/:id/delete') do
    id = params[:id]
    db = connect_to_db()
    post_user_id = db.execute("SELECT user_id FROM posts where id = ?",id)

    if post_user_id != []
        user_role=db.execute("SELECT role_id FROM users where id=?",session[:id]).first
        if session[:id]==post_user_id[0][0] || user_role[0] == 1
            db.execute("DELETE FROM posts WHERE id = ?",id)
     
        else
    
        end
    else
      
    end
    redirect("/users/#{session[:id]}")
end


get('/users/new') do  
    slim(:'users/new')
end

post('/users') do
    username = params[:username]
    email = params[:email]
    password = params[:password]
    password_confirm = params[:password_confirm]

    session[:regattempt]=0

    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = connect_to_db()
      db.execute("INSERT INTO users (name,role_id,pwdigest,email) VALUES (?,?,?,?)",username,0,password_digest,email)
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

get('/user/login') do
    slim(:'users/login')
end

get('/users/:id') do
    id = session[:id]
    db=connect_to_db()
    db.results_as_hash = true
    posts = db.execute("SELECT * FROM posts WHERE user_id = ?",id)
    slim(:'users/show', locals:{posts:posts})
end

post('/login') do
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
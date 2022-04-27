require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions






get('/') do
  slim(:index)
end

get('/pictures') do
    keys=show_posts_topic(1,session[:id])
    slim(:'posts/index_pictures', locals:{posts:keys[0],users:keys[1], current_user:keys[2]})

end
get('/spots') do
    keys=show_posts_topic(2,session[:id])
    slim(:'posts/index_spots', locals:{posts:keys[0],users:keys[1], current_user:keys[2]})

end
get('/bogos') do
    keys=show_posts_topic(3,session[:id])
    slim(:'posts/index_bogos', locals:{posts:keys[0],users:keys[1], current_user:keys[2]})
end

get('/posts/new') do
    slim(:'posts/new')
end

get('/posts/:id') do
    id = params[:id]
    keys = show_post(id)
    slim(:'posts/show', locals:{post:keys[0],user:keys[1],tags:keys[2]})
end

post('/posts/create') do
    id = session[:id] 
    title = params[:title]
    body=params[:body]
    topic = params[:topic].to_i
    file = params[:file]
    create_post(id,title,body,topic,file)
    redirect("/posts/new")    
end

post('/post/:id/tags') do
    post_id = params[:id]
    post_tag = params[:tag]
    add_remove_tags(post_id,post_tag)
    redirect("/posts/#{post_id}")
end

post('/post/:id/update') do
    post_id = params[:id]
    title = params[:title]
    body = params[:body]
    update_post(post_id,title,body)
    redirect("posts/#{post_id}")
end

post('/post/:id/delete') do
    id = params[:id]
    delete_post(id)
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
    session[:regattempt] = new_user(username,email,password,password_confirm)
    if session[:regattempt]== nil
        redirect('/')
    else
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
    posts =show_user(id)
    slim(:'users/show', locals:{posts:posts})
end

post('/users/:id/update/email') do
    email = params[:email]
    update_user_email(email)
end
post('/users/:id/update/password') do
    old_password=params[:password_old]
    new_password=params[:password]
    new_password_confirm=params[:password_confirm]
    update_user_pw(old_password,new_password,new_password_confirm)
end

post('/login') do
    username = params[:username]
    password = params[:password]
    login(username,password)
end
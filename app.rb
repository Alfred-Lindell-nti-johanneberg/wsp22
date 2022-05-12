require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions

include Model

# 
# display landing page
# 
get('/') do
  slim(:index)
end

# 
# Displays posts with the topic pictures
# 
# @see Model#show_posts_topic
get('/pictures') do
    keys=show_posts_topic(1,session[:id])
    slim(:'posts/index_pictures', locals:{posts:keys[0],users:keys[1], current_user:keys[2]})
end

# 
# Displays posts with the topic birdwatching spots
#
# @see Model#show_posts_topic
get('/spots') do
    keys=show_posts_topic(2,session[:id])
    slim(:'posts/index_spots', locals:{posts:keys[0],users:keys[1], current_user:keys[2]})
end

# 
# Displays posts with the topic bogos binted
#
# @see Model#show_posts_topic
get('/bogos') do
    keys=show_posts_topic(3,session[:id])
    slim(:'posts/index_bogos', locals:{posts:keys[0],users:keys[1], current_user:keys[2]})
end

# 
# Displays a form where you can create a new post
#
get('/posts/new') do
    slim(:'posts/new')
end

# 
# Displays the post with this id
# 
# @param [integer] id The id of post shown
# 
# @see Model#show_post
get('/posts/:id') do
    id = params[:id]
    keys = show_post(id)
    slim(:'posts/show', locals:{post:keys[0],user:keys[1],tags:keys[2]})
end

# 
# Checks if user is logged in and if all fields have been filled in, then creates a post
# 
# @param [string] title The title of new post
# @param [string] body The bodytext of new post
# @param [integer] topic The topic the post will be in
# @param [nil/array<Hash>] file The information of attatched img file, or nil if no file has been attatched
# 
# @see Model#empty_string?
# @see Model#create_post
post('/posts/create') do
    id = session[:id] 
    title = params[:title]
    body=params[:body]
    topic = params[:topic].to_i
    file = params[:file]
    if session[:id]==nil
        redirect('/posts/new')
    end
    if empty_string?(title) || empty_string?(body)
        session[:create_post_error] = "One or more of your fields are empty, please fill them in"
        redirect("/posts/new")
    else
        session[:create_post_error] = ""
        create_post(id,title,body,topic,file)
        redirect("/posts/#{id}")   
    end 
end

# 
# Checks if the user owns the post and then adds tag to/removes tag from post 
# 
# @param [integer] post_id The ID of post
# @param [string] post_tag The tag that will be added to/removed from post
# 
# @see Model#user_id_by_post_id
# @see Model#add_remove_tags
post('/post/:id/tags') do
    post_id = params[:id]
    post_tag = params[:tag]
    if user_id_by_post_id(post_id) == session[:id]
        add_remove_tags(post_id,post_tag)
        redirect("/posts/#{post_id}")
    end
end

# 
# Updates the title and body of a post if session id == the posts user_id
# 
# @param [integer] id The id of post
# @param [string] title The new title to post
# @param [string] body The new textbody to post
# 
# @see Model#update_post
# @see Model#user_id_by_post_id
post('/post/:id/update') do
    post_id = params[:id]
    title = params[:title]
    body = params[:body]
    if user_id_by_post_id(post_id) == session[:id]
        update_post(post_id,title,body)
        redirect("posts/#{post_id}")
    end
end

# 
# Checks if the user owns the post or if they are an admin, only then does it delete the post with id = id
# 
# @param [integer] id The id of post
# 
# @see Model#is_admin?
# @see Model#delete_post
post('/post/:id/delete') do
    post_id = params[:id]
    if session[:id] !=nil
        if user_id_by_post_id(post_id) == session[:id] || is_admin?(session[:id])
            delete_post(id)
        end
    end
    redirect("/users/#{user_id}")
end

# 
# Displays a form where you can create a new post
# 
get('/users/new') do  
    slim(:'users/new')
end

# 
# Creates a new user with information from parasm inserted to db if no fields were empty and if username does not already exist
# 
# @param [string] username Name of new user
# @param [string] email The email of new user
# @param [string] password The password of new user
# @param [string] password_confirm A string used to check user can write the same password twice in a row
# 
# @see Model#empty_string?
# @see Model#username_exist?
# @see Model#new_user
post('/users') do
    username = params[:username]
    email = params[:email]
    password = params[:password]
    password_confirm = params[:password_confirm]
    session[:regattempt]=0
    if empty_string?(username) || empty_string?(email) || empty_string?(password) || empty_string?(password_confirm)
        session[:regattempt_error] = "Lämna inget fält tomt"
        session[:regattempt]+=1
        redirect('/users/new')
    else
        session[:regattempt_error] = ""
    end
    if username_exist?(username)
        session[:regattempt_error] = "Username already exists, please try a different username."
        session[:regattempt]+=1
        redirect('/users/new')
    else
        session[:regattempt_error] = ""
    end

    session[:regattempt] = new_user(username,email,password,password_confirm)
    
    if session[:regattempt]== nil
        redirect('/')
    else
        redirect('/users/new')
    end
    
end

# 
# Destroys session, effectiely logging out of account
#
get('/logout') do
    session.destroy
    redirect('/')
end

# 
# Displays a form where you can login to an existing account
# 
get('/user/login') do
    slim(:'users/login')
end

# 
# Shows the page of a user alongside all of their posts, forms to delete posts and forms to update password and email
# 
# @param [integer] id The ID of The user whose page is being shown
# 
# @see Model#show_user
get('/users/:id') do
    user_page_id = params[:id]
    posts =show_user(user_page_id)
    slim(:'users/show', locals:{posts:posts,user_page_id:user_page_id})
end

# 
# Updates the email of a user
# 
# @param [string] email New email of user
# 
# @see Model#update_user_email
post('/users/:id/update/email') do
    email = params[:email]   
    session[:email] = update_user_email(email,session[:id])
    redirect("/users/#{session[:id]}")
end

# 
# Updates password of user if the user being updated is same as the one logged in, the old password is the correct password and if new pw is same as new pw_confirm
# 
# @param [integer] user_page_id The ID of the user whose page you are on
# @param [string] old_password The old password of user
# @param [string] new_password the new password of user
# @param [string] new_password_confirm New password confirm
# 
# @see Model#select_user_by_name
# @see Model#correct_password_to_user
# @see Model#update_user_pw
post('/users/:id/update/password') do
    user_page_id = params[:id]
    old_password=params[:password_old]
    new_password=params[:password]
    new_password_confirm=params[:password_confirm]
    session[:change_pw_err] = ""
    user = select_user_by_name(session[:username])
    if user_page_id==user["id"] || correct_password_to_user(old_password,user)
        if new_password==new_password_confirm
            update_user_pw(new_password,user["id"])
        else
            session[:change_pw_err] = "Dina nya lösenord matchade inte"
        end
    else
        session[:change_pw_err] = "Fel lösen"

    end
    redirect("/users/#{session[:id]}")
end

# 
# Loggs in to existing user, prevents brute force hacking, checks for empty fields, Checks if user exists and checks if password is correct
# 
# @param [string] username The name of user that wants to log in
# @param [sting] password The Password of user that wants to log in
# 
# @see Model#empty_string?
# @see Model#select_user_by_name
# @see Model#correct_password_to_user
post('/login') do
    username = params[:username]
    password = params[:password]
    
    session[:loginattempt]=0 if Time.new.to_i - session[:last_attempt].to_i > 300
    if session[:loginattempt] > 4
        session[:signinerror] = 'För många misslyckade försök. Var vänlig och försök igen senare'
        redirect('/user/login') 
    end
    if empty_string?(username) || empty_string?(password)
        session[:signinerror] = "Lämna inget fält tomt"
        session[:loginattempt]+=1
        redirect('/users/new')
    end
    user = select_user_by_name(username)
    if user==nil 
        session[:loginattempt] +=1
        session[:last_attempt] = Time.now
        redirect('/user/login')
    end 
    if correct_password_to_user(password,user)
        session[:id]= user["id"]
        session[:username] = username
        session[:email] = user["email"]
        session[:loginattempt] = nil
        session[:signinerror] = ""
        return redirect('/')
    else
        session[:loginattempt] +=1
        session[:last_attempt] = Time.now
        return redirect('/user/login')
    end
end
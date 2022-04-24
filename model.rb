def connect_to_db()
    db = SQLite3::Database.new("db/Birdwatch_forum.db")
end

def show_posts_topic(topic_id)
    db = connect_to_db()
    db.results_as_hash = true
    posts = db.execute("SELECT * FROM posts WHERE topic_id = ?",topic_id)
    users = db.execute("SELECT * FROM users")
    if session[:id] == nil
        current_user = nil
    else
        current_user= db.execute("SELECT role_id FROM users WHERE id = ?",session[:id]).first
    end
    return [posts,users,current_user]
end

def show_post(id)
    db = connect_to_db()
    db.results_as_hash = true
    post = db.execute("SELECT * FROM posts WHERE id = ?",id).first
    user = db.execute("SELECT * FROM posts INNER JOIN users ON users.id = posts.user_id WHERE posts.id = ? ",id).first
    tags = db.execute("SELECT * FROM tags INNER JOIN posts_tags_rel ON tags.id = posts_tags_rel.tags_id WHERE posts_tags_rel.posts_id = ?",id)
    return [post,user,tags]
end

def create_post(id,title,body,topic,file)
    if file && file[:filename]
        path = File.join("./public/img/",file[:filename])
        path_for_db = File.join("img/",file[:filename])
        file=params[:file][:tempfile]
        File.open(path, 'wb') do |f|
            f.write(file.read)
        end
    else
        path_for_db = nil
    end
    db = connect_to_db()
    db.execute("INSERT INTO posts (title, body, user_id, topic_id,img_path) VALUES (?, ?, ?, ?,?)",title,body,id,topic,path_for_db)
end

def update_post(post_id,title,body)
    db=connect_to_db()
    db.execute("UPDATE posts SET (title,body) = (?,?) WHERE id=? ",title,body,post_id)
end

def add_remove_tags(post_id,post_tag)
    db=connect_to_db()
    db.results_as_hash=true
    tags = db.execute("SELECt * FROM tags")
    #kolla om given tag redan finns i tags table och lägg då till den
    @tag_exists = false
    tags.each do |tag|
        p tag["name"]
        if tag["name"]==post_tag
            @tag_exists=true
        end
    end
    if @tag_exists == false 
        db.execute("INSERT INTO tags (name) VALUES (?)",post_tag)
    end
    # kolla om taggen finns på post:en eller inte
    post_tag_id = db.execute("SELECT id FROM tags WHERE name=?",post_tag).first["id"] # name är unikt så det finns bara en av alla tags
    if db.execute("SELECT * FROM posts_tags_rel WHERE (posts_id,tags_id) = (?,?)",post_id,post_tag_id).first == nil
        db.execute("INSERT INTO posts_tags_rel (posts_id,tags_id) VALUES (?,?)",post_id,post_tag_id)
    else #finns det redan taggen på posten så tas relationen bort från posts_tags_rel
        db.execute("DELETE FROM posts_tags_rel WHERE (posts_id,tags_id) = (?,?)",post_id,post_tag_id)
    end
end

def delete_post(id)
    db = connect_to_db()
    post_user_id = db.execute("SELECT user_id FROM posts where id = ?",id)
    path = db.execute("SELECT img_path FROM posts where id = ?", id).first
    p path
    if post_user_id != []
        user_role=db.execute("SELECT role_id FROM users where id=?",session[:id]).first
        if session[:id]==post_user_id[0][0] || user_role[0] == 1
            db.execute("DELETE FROM posts WHERE id = ?",id)
            db.execute("DELETE FROM posts_tags_rel WHERE posts_id = ?",id)
            File.delete("./public/#{path[0]}") if File.exist?("./public/#{path[0]}")
        end      
    end
    return redirect("/users/#{session[:id]}")
end

def new_user(username,email,password,password_confirm)
    
    session[:regattempt]=0

    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = connect_to_db()
      db.execute("INSERT INTO users (name,role_id,pwdigest,email) VALUES (?,?,?,?)",username,0,password_digest,email)
      session[:regattempt]=nil
      return redirect('/')
    else
      session[:regattempt]+=1
      return redirect('/register')
    end
end

def login(username,password)
    db = connect_to_db()
    db.results_as_hash = true
    session[:loginattempt]=0 if Time.new.to_i - session[:last_attempt].to_i > 300
    if session[:loginattempt] > 4
        session[:signinerror] = 'För många misslyckade försök. Var vänlig och försök igen senare'
        return redirect('/user/login')
    end
    result = db.execute("SELECT * FROM users WHERE name = ?",username).first
    if result==nil 
        session[:loginattempt] +=1
        session[:last_attempt] = Time.now
        return redirect('/user/login')
    end  
    pwdigest = result["pwdigest"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:id]= id
        session[:username] = username
        session[:email] = result["email"]
        session[:loginattempt] = nil
        session[:signinerror] = ""
        return redirect('/')
    else
        session[:loginattempt] +=1
        session[:last_attempt] = Time.now
        return redirect('/user/login')
    end
end

def update_user_pw(old_password,new_password,new_password_confirm)
    db = connect_to_db()
    db.results_as_hash=true
    session[:regattempt]=0
    session[:change_pw_err] = ""
    pwdigest_old = db.execute("SELECT * FROM users WHERE id = ?",session[:id]).first["pwdigest"]
    if BCrypt::Password.new(pwdigest_old) == old_password
        if (new_password == new_password_confirm)
            password_digest = BCrypt::Password.create(new_password)
            
            db.execute("UPDATE users SET pwdigest = ? WHERE id=?",password_digest,session[:id])
            
        else
            session[:change_pw_err] = "Fel lösen eller dina nya lösenord matchade inte"

        end

    else
        session[:change_pw_err] = "Fel lösen eller dina nya lösenord matchade inte"
    end
    return redirect("/users/#{session[:id]}")
end

def update_user_email(email)
    db=connect_to_db()
    db.execute("UPDATE users SET email= ? WHERE id=? ",email,session[:id])
    session[:email]=email
    return redirect("/users/#{session[:id]}")
end

def show_user(id)
    db=connect_to_db()
    db.results_as_hash = true
    return db.execute("SELECT * FROM posts WHERE user_id = ?",id)
end
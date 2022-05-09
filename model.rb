#  Model help functions
module Model

    #
    # connects to and database saves database to a variable 'db' 
    #
    # @return [array<Hash>] returns db
    #
    def connect_to_db()
        db = SQLite3::Database.new("db/Birdwatch_forum.db")
    end


    #
    # takes topic_id and user_id and return an array of variables
    #
    # @param [integer] topic_id the id of what page we are on
    # @param [integer/nil] user_id session[:id] of current user
    #
    # @return [array] returns an array with [posts,users,current_user] where posts are every post with topic_id=topic_id, users are an array with hashes of every user in db, and current user is role_id of logged in user (or nil if not logged in) 
    #
    def show_posts_topic(topic_id,user_id)
        db = connect_to_db()
        db.results_as_hash = true
        posts = db.execute("SELECT * FROM posts WHERE topic_id = ?",topic_id)
        users = db.execute("SELECT * FROM users")
        if user_id == nil
            current_user = nil
        else
            current_user= db.execute("SELECT role_id FROM users WHERE id = ?",session[:id]).first
        end
        return [posts,users,current_user]
    end

    #
    # takes the id of a post and returns an array of variables taken from db
    #
    # @param [integer] id the id of a post
    #
    # @return [array] returns [post,user,tags] where post is an array of hashes with information about the post with id=id, user is an array with hashes with information about the user who made the post and tags is an array with every tag the post has.
    #
    def show_post(id)
        db = connect_to_db()
        db.results_as_hash = true
        post = db.execute("SELECT * FROM posts WHERE id = ?",id).first
        user = db.execute("SELECT * FROM posts INNER JOIN users ON users.id = posts.user_id WHERE posts.id = ? ",id).first
        tags = db.execute("SELECT * FROM tags INNER JOIN posts_tags_rel ON tags.id = posts_tags_rel.tags_id WHERE posts_tags_rel.posts_id = ?",id)
        return [post,user,tags]
    end

    #
    # Takes information about a post and creates it, also checks if a file is attatched, saves it and saves a path to it that will be in the database, if a file is not attatched then nil will be placed in place of a filepath.
    #
    # @param [integer] user_id the id of logged in user
    # @param [string] title the title of new post
    # @param [string] body the body text of new post
    # @param [integer] topic the topic the new post will be in
    # @param [nil/array<Hash>] file either nil (no file) or an array with hashes with information of the attatched file
    #
    # @return [nil] nothing
    #
    def create_post(user_id,title,body,topic,file)
        if file && file[:filename]
            path = File.join("./public/img/",file[:filename])
            path_for_db = File.join("img/",file[:filename])
            tempfile=file[:tempfile]
            File.open(path, 'wb') do |f|
                f.write(tempfile.read)
            end
        else
            path_for_db = nil
        end
        db = connect_to_db()
        db.execute("INSERT INTO posts (title, body, user_id, topic_id,img_path) VALUES (?, ?, ?, ?,?)",title,body,user_id,topic,path_for_db)
        return nil
    end

    #
    # takes the id of a post, new title and new bodytext and updates the title and body with the new ones.
    #
    # @param [integer] post_id The id of a post
    # @param [string] title the new title to post
    # @param [string] body the new body to post
    #
    # @return [nil] nothing
    #
    def update_post(post_id,title,body)
        db=connect_to_db()
        db.execute("UPDATE posts SET (title,body) = (?,?) WHERE id=? ",title,body,post_id)
    end

    #
    # takes the id of a post and a tag, then checks if the tag already exists in database and adds it to database if not. After that it checks if the post already has the tag, if true then it removes tag from post in relation table, if false the it adds a relation between tag and post in ralations table.
    #
    # @param [integer] post_id the id of a post
    # @param [string] post_tag A tag, new or preexisting
    #
    # @return [nil] nothing
    #
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
        return
    end

    #
    # Delets post where ID = post_id if user is logged in and owns the post or is admin. Also cascades any files attatched and relations with tags.
    #
    # @param [integer] post_id The ID of post
    # @param [integer] user_id The ID of logged in user
    #
    # @return [nil] nothing
    #
    def delete_post(post_id,user_id)
        db = connect_to_db()
        post_user_id = db.execute("SELECT user_id FROM posts where id = ?",post_id)
        path = db.execute("SELECT img_path FROM posts where id = ?", post_id).first
        p path
        if post_user_id != []
            user_role=db.execute("SELECT role_id FROM users where id=?",session[:id]).first
            if user_id==post_user_id[0][0] || user_role[0] == 1
                db.execute("DELETE FROM posts WHERE id = ?",post_id)
                db.execute("DELETE FROM posts_tags_rel WHERE posts_id = ?",post_id)
                if path[0]!=nil
                    File.delete("./public/#{path[0]}") if File.exist?("./public/#{path[0]}")
                end
            end      
        end
        return redirect("/users/#{user_id}")
    end

    #
    # Takes a name and checks if name already exists in database and retruns a boolean
    #
    # @param [string] name Any name you want to check
    #
    # @return [boolean] Retruns true/false if username exists/does not exist
    #
    def username_exist?(name)
        db = connect_to_db()
        db.results_as_hash = true
        usernames = db.execute("SELECT name FROM users")
        usernames.each do |user|
            if user["name"]==name
                return true
            end
        end
        return false
    end

    #
    # takes a sting and checks if it is empty or not
    #
    # @param [sting] string given string of any size
    #
    # @return [boolean] retruns true if string is empty and false if not
    #
    def empty_string?(string)
        return string == ""
    end

    #
    # takes the id of a user and checks in role_id == 1, returns result
    #
    # @param [integer] id the id of a user
    #
    # @return [boolean] retuns true or false depending on role_id==1
    #
    def id_admin?(id)
        db = connect_to_db()
        return 1==db.execute("SELECT role_id FROM users where id=?",id).first
    end

    #
    # takes the id of a post and returns the id of the user who posted it
    #
    # @param [integer] post_id the id of a post
    #
    # @return [integer] the id of the user who made the post
    #
    def user_id_by_post_id(post_id)
        db = connect_to_db
        return db.execute("SELECT FROM posts user_id WHERE id = ?",post_id).first
    end

    #
    # takes username, email, password and password_confirm and checks if password==password_confrim. If true, make a new user in the database and regattempt=nil. If false, iterate regattempt. Returns regattempt
    #
    # @param [string] username username of new user
    # @param [string] email email of new user
    # @param [string] password password of new user
    # @param [string] password_confirm used to check if user wrote the same password twice
    #
    # @return [integer/nil] returns regattempt which is either 1 or nil
    #
    def new_user(username,email,password,password_confirm)    
    regattempt=0
            if (password == password_confirm)
        password_digest = BCrypt::Password.create(password)
        db = connect_to_db()
        db.execute("INSERT INTO users (name,role_id,pwdigest,email) VALUES (?,?,?,?)",username,0,password_digest,email)
        regattempt = nil
        return regattempt
        else
        regattempt +=1
        return regattempt
        end
    end

    #
    # selects and retruns the information of a user where username=username
    #
    # @param [string] username the username of wanted user
    #
    # @return [array<Hash>] the information of a user in the form of an array of hashes
    #
    def select_user_by_name(username)
        db = connect_to_db()
        db.results_as_hash = true
        return db.execute("SELECT * FROM users WHERE name = ?",username).first
    end

    #
    # takes a given password and hash of a user to check if the password is the users
    #
    # @param [string] password A given password in the form of a string
    # @param [array<Hash>] user An array of hashes related to a given 
    #
    # @return [boolean] true or false depending on wheter or not given password is the same as user["pwdigest"]
    #
    def correct_password_to_user(password,user)
        return BCrypt::Password.new(password) == user["pwdigest"]
    end


    #
    # opens the database and updates a users password
    #
    # @param [string] new_password the new encrypted password that overwrites old encrypted password where user_id
    # @param [integer] user_id the id of the user having his password uppdated
    #
    # @return [nil] nothing
    #
    def update_user_pw(new_password,user_id)
        db = connect_to_db()
        db.execute("UPDATE users SET pwdigest = ? WHERE id=?",BCrypt::Password.new(new_password),user_id)
        retrun nil
    end

    #
    # updates the email of user with the given id
    #
    # @param [string] email the given email that will overwrite the old one
    # @param [integer] id the id of the user having its email uppdated
    #
    # @return [string] returns the new email
    #
    def update_user_email(email,id)
        db=connect_to_db()
        db.execute("UPDATE users SET email= ? WHERE id=? ",email,id)   
        return email
    end

    #
    # retruns the information of a user where id = id
    #
    # @param [integer] id the id of wanted user
    #
    # @return [array<Hash>] the information of a user in the form of an array of hashes
    #
    def show_user(id)
        db=connect_to_db()
        db.results_as_hash = true
        return db.execute("SELECT * FROM posts WHERE user_id = ?",id)
    end
end
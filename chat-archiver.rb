require 'sinatra'
require 'sinatra/partial'
require 'slack/client'
require 'rubygems'
require 'json'
require 'date'

set :partial_template_engine, :erb

require_relative 'models'

SLACK_API_TOKEN=ENV["SLACK"]

def create_archives
  @archives = Channel.last.archives
end

def create_current_archive
  @current_archive = Archive.create(:ts => Time.now)
end

def create_channel(argument)
  channel = Channel.first_or_create
  channel.name = argument
  channel.save
end

def sync_slack_clients(client)
  @users_data = JSON.parse(client.users.list)
  @channel_members_data = @users_data["members"]

  list_member_data(@channel_members_data)
end

def list_member_data(members_data_hash)
  #Members are listed in alphabetical order by first name
  members_data_hash.length.times do |member_number|
    update_or_create_user_attributes(members_data_hash[member_number])
  end
end

def update_or_create_user_attributes(member_data_hash_in_alphabetical_order)
  user_information_hash = member_data_hash_in_alphabetical_order

  update_or_create_users(user_information_hash)
end

def update_or_create_users(user_information_hash)
  user_information_hash = user_information_hash
    #the following variables are named after the corresponding data items passed to this application from the Slack API
    @slack_id = user_information_hash["id"]

    @name = user_information_hash["name"]

    @profile = user_information_hash["profile"]

    @first_name = @profile["first_name"]

    @last_name = @profile["last_name"]

    @image_24 = @profile["image_24"]

    @image_32 = @profile["image_32"]

    @image_48 = @profile["image_48"]

    @image_72 = @profile["image_72"]

    @image_192 = @profile["image_192"]

    @image_original = @profile["image_original"]

    @title = @profile["title"]

    @email = @profile["email"]

    time = Time.now

    @updated_at = time

    user = User.first_or_create(:slack_id => @slack_id, :name => @name, :first_name => @first_name, :last_name => @last_name, :image_24 => @image_24, :image_32 => @image_32,:image_48 => @image_48,:image_72 => @image_72,:image_192 => @image_192,:image_original => @image_original,:title => @title,:email => @email,:updated_at => @created_at)

  save_users(user)
end

def save_users(user)

  @users << user

  if @users.save
    #users are saved
  else
    #add partial that displays an appropriate message on the home page
  end
end


helpers do
  def default_channel
    @default_channel ||= Channel.last
  end
end

get "/" do
  erb :home
end

def client
  client = Slack::Client.new(token: SLACK_API_TOKEN)
end


get("/users") do
  @users = Channel.last.users

  erb :users
end

get "/archives" do
  create_archives

  erb :archives
end

get("/archive/:id") do
  @archive = Archive.get params[:id]

  @users = User.all

  @users.each do |user|
    user["slack_id"]
    user["name"]
  end

  erb(:archive)
end

def add_current_archive_to_archives
  create_archives
  create_current_archive
  @archives << @current_archive
  save_archives(@archives)
end

def save_archives(archives)
  @archives.save
end

def fetch_chat_number_param
  chat_number_param = params().fetch("number")
  number_of_chats_requested(chat_number_param)
end

def number_of_chats_requested(chat_number_param)
  number = chat_number_param[:chat_number]

  get_message_data(number)
end

def get_message_data(number)
  p "_____ number ______"
  p number

  p "______ client _____"
  puts client


  p "**** @message_data *****"
  p message_data = JSON.parse(client.channels.history(:channel=>ENV["SLACK_CHANNEL"],:count=>number))
  get_messages_data(message_data)
end

def get_messages_data(message_data)
  "-______ message_data ______"
  p message_data
  messages_data = message_data["messages"]

  p "****** messages_data in get messsages_data ********"
  p messages_data
  messages_do(messages_data)
end

def messages_do(messages_data)
  messages_data = messages_data
  p "**** messages_data *****"
  p messages_data
  p "***** messages_data.count *****"
  p messages_data.count

  messages_data.count.times do |message|
     p "message_num"
     p message_num = message
     puts message_num = message
     message_num = message
     get_message_hash(messages_data,message_num)
  end
end

def get_message_hash(messages_data,message_num)

  message_hash = messages_data[message_num]
  build_chat(message_hash)
end

def build_chat(message_hash)
  @user = message_hash["user"]

  @text = message_hash["text"]

  @attachments = message_hash["attachments"]


  puts "attachments"
  puts @attachments.class
  if @attachments.class == Array
    @attachments.count.times do |attachment|
      attach_hash = @attachments[attachment]

      @title = attach_hash["title"]
      puts "title"
      puts @title
      puts "title_link"
      @title_link = attach_hash["title_link"]
      puts @title_link
      puts "attach text"
      @attach_text = attach_hash["text"]
      puts "fallback"
      @fallback = attach_hash["fallback"]
      puts @fallback
      puts "thumb_url"
      @thumb_url = attach_hash["thumb_url"]
      puts @thumb_url
      puts "from_url"
      @from_url = attach_hash["from_url"]
      puts @from_url
      puts "thumb_width"
      @thumb_width = attach_hash["thumb_width"]
      puts @thumb_width
      puts "thumb_height"
      @thumb_height = attach_hash["thumb_height"]
      puts @thumb_height

    end
  end

  @ts = message_hash["ts"]
  p "**** @ts *****"
  puts @ts
  p "*****"

  create_chat
end

def create_chat
  @chat = Chat.create(:user => @user,:text => @text,:ts => @ts,:attachments => @attachments,:title => @title,:title_link => @title_link,:attach_text => @attach_text,:fallback => @fallback,:thumb_url =>@thumb_url,:from_url => @from_url,:thumb_width => @thumb_width,:thumb_height => @thumb_height)

  p " ****** @chat *****"
  p @chat
  add_chat_to_current_archive(@chat)
end

def add_chat_to_current_archive(chat)
  p "_____ current_archive before______"
  @current_archive
  @current_archive.chats << @chat

  p "_____ current_archive after______"
  @current_archive

  save_chat(@current_archive)
end

def save_chat(current_archive)
 if @current_archive.save
   # my_account is valid and has been saved
  else
    puts 'chats errors any'
    puts @current_archive.chats.any? { |chat| chat.errors.any? }

    @current_archive.chats.each do |chat|
     chat.errors.each do |error|
       p error
     end
    end
  end

  if @chat.saved?()
    redirect "/archive/#{@current_archive.id}"
  else
    redirect "/"
  end
end

post "/chats" do

  add_current_archive_to_archives

  p "***** @archvies *****"
  p @archives

  p "***** @current_archive *****"
  p @current_archive

  puts "***** @current_archive.id "

  puts @current_archive.id

  fetch_chat_number_param

end


post "/notes" do

  note_attrs = params[:note]
  p archive = params[:archive_id]

  @current_archive = Archive.get(archive)

  @note = Note.new(note_attrs)

  @current_archive.notes << @note

  @current_archive.save


  if @current_archive.save
     # my_account is valid and has been saved
    else
      puts 'notes errors any'
      puts @current_archive.notes.any? { |note| note.errors.any? }

      @current_archive.notes.each do |note|
       note.errors.each do |error|
         p error
       end
     end
  end

  if @note.saved?()
    redirect "/archive/#{@current_archive.id}"
  else
    redirect "/"
  end

end

put "/notes/:note_id" do
  note_id = params[:note_id]
  note_attrs = params[:note]

  note = Note.get(note_id)
  note.update(note_attrs)

  if request.xhr?
    partial :'partials/note', :locals => { :note => note }
  else
    redirect "/archive/#{note.archive_id}"
  end
end

delete "/notes/:note_id" do
  note_id = params[:note_id]
  note_attrs = params[:note]

  note = Note.get(note_id)
  note.destroy

  if request.xhr?
    note_id
  else
    redirect "/archive/#{note.archive_id}"
  end
end

post "/chats/:num" do
  num = params[:num]
  @archives = default_channel.archives
  @current_archive = Archive.create(:ts => Time.now)
  @archives << @current_archive
  @archives.save

  client = Slack::Client.new(token: SLACK_API_TOKEN)
  @message_data = JSON.parse(client.channels.history(:channel=>ENV["SLACK_CHANNEL"],:count=>num))

  @messages_data = @message_data["messages"]

  # @messages_data.count.times do |x|

  #   message_hash = @messages_data[x]


  #   @user = message_hash["user"]

  #   @text = message_hash["text"]

  #   @ts = message_hash["ts"]

  #   @chat = Chat.create(:text => @text)

  #   @current_archive.chats << @chat


  #   if @current_archive.save
  #    # my_account is valid and has been saved
  #   else
  #     puts 'chats errors any'
  #     puts @current_archive.chats.any? { |chat| chat.errors.any? }

  #     @current_archive.chats.each do |chat|
  #      chat.errors.each do |error|
  #        p error
  #      end
  #    end
  #  end



  # end

  # if @chat.saved?()
  #   erb(:chats)
  # else
  #   redirect "/"
  # end
  erb(:chats)
end
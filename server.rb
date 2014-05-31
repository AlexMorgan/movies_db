require 'sinatra'
require 'pry'
require 'pg'
require 'shotgun'

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

def query(sql_statement)
  db_connection do |conn|
    conn.exec(sql_statement)
  end
end

def query_find(sql_statement)
  id = params[:id]
  # To prevent this we want to sanitize any input that we accept from users. We can use placeholders
  # within a query and then provide values for those placeholders that get filtered for any malicious
  # characters before they are inserted into the statement. The exec_params method will perform this filtering for us:
  db_connection do |conn|
    conn.exec_params(sql_statement, [id])
  end
end


#------------------------------------------ Routes ------------------------------------------
get '/' do
  erb :index
end

get '/actors' do
  @actors =  query('SELECT * FROM actors ORDER BY name ASC')
  erb :'/actors/index'
end

get '/actors/:id' do
  @actor_details = query_find('SELECT actors.name, movies.year, movies.title, movies.id AS movie_id, cast_members.character FROM movies
      JOIN cast_members ON movies.id = cast_members.movie_id
      JOIN actors ON actors.id = cast_members.actor_id
    WHERE actors.id = $1 ORDER BY year ASC')
  erb :'/actors/show'
end

get '/movies' do
  @movies =  query('SELECT * FROM movies ORDER BY title ASC')
  erb :'/movies/index'
end

get '/movies/:id' do
  @movie_detail = query_find('SELECT movies.title, movies.year, genres.name AS genre, studios.name AS studio_name, actors.name AS actor, actors.id AS actor_id, cast_members.character FROM movies
      JOIN genres ON movies.genre_id = genres.id
      JOIN studios ON movies.studio_id = studios.id
      JOIN cast_members ON movies.id = cast_members.movie_id
      JOIN actors ON actors.id = cast_members.actor_id
    WHERE movies.id = $1')
  erb :'movies/show'
end






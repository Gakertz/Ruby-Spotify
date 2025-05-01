require 'json'
require 'net/http'
require 'uri'
require 'base64'  # Este require faltaba

# -----------------------------
# Parte 1: Leer las credenciales desde credentials.json
# -----------------------------
credenciales = JSON.parse(File.read("credentials.json"))
client_id = credenciales["client_id"]
client_secret = credenciales["client_secret"]


# -----------------------------
# Parte 2: Obtener el token de acceso
# -----------------------------
token_codificado = Base64.strict_encode64("#{client_id}:#{client_secret}")
uri_token = URI("https://accounts.spotify.com/api/token")

solicitud_token = Net::HTTP::Post.new(uri_token)
solicitud_token["Authorization"] = "Basic #{token_codificado}"
solicitud_token.set_form_data("grant_type" => "client_credentials")  # Estaba mal escrito antes

respuesta_token = Net::HTTP.start(uri_token.hostname, uri_token.port, use_ssl: true) do |http|
  http.request(solicitud_token)
end

token_acceso = JSON.parse(respuesta_token.body)["access_token"]

# -----------------------------
# Parte 3: Lista de IDs de artistas
# -----------------------------
ids_artistas = [
  '4gzpq5DPGxSnKTe4SA8HAU', 
  '06HL4z0CvFAxyc27GXpf02',  
  '53XhwfbYqKCa1cC15pYq2q',
  '4q3ewBCX7sLwd24euuV69X', 
  '2ye2Wgw4gimLv2eAKyk1NB', 
  '0C0XlULifJtAgn6ZNCW2eu', 
  '6vWDO969PvNqNYHIOW5v0m', 
  '6eUKZXaKkcviH0Ku9w2n3V', 
  '0EmeFodog0BfCgMzAIvKQp',
  '1vCWHaC5f2uS3yhpwWbIA6'   
]

# -----------------------------
# Parte 4: Obtener datos para cada artista
# -----------------------------
datos_artistas = []

ids_artistas.each do |id_artista|
  # Obtener información del artista
  uri_artista = URI("https://api.spotify.com/v1/artists/#{id_artista}")
  solicitud_artista = Net::HTTP::Get.new(uri_artista)
  solicitud_artista["Authorization"] = "Bearer #{token_acceso}"

  respuesta_artista = Net::HTTP.start(uri_artista.hostname, uri_artista.port, use_ssl: true) do |http|
    http.request(solicitud_artista)
  end

  info_artista = JSON.parse(respuesta_artista.body)
  nombre_artista = info_artista["name"]
  popularidad_artista = info_artista["popularity"]

  # Obtener canción más popular en Chile
  uri_canciones = URI("https://api.spotify.com/v1/artists/#{id_artista}/top-tracks?market=CL")
  solicitud_canciones = Net::HTTP::Get.new(uri_canciones)
  solicitud_canciones["Authorization"] = "Bearer #{token_acceso}"

  respuesta_canciones = Net::HTTP.start(uri_canciones.hostname, uri_canciones.port, use_ssl: true) do |http|
    http.request(solicitud_canciones)
  end

  canciones = JSON.parse(respuesta_canciones.body)["tracks"]

  mejor_cancion = canciones.max_by { |c| [c["popularity"] || 0, -c["name"].ord] }
  nombre_cancion = mejor_cancion ? mejor_cancion["name"] : ""
  url_preview = mejor_cancion && mejor_cancion["external_urls"] && mejor_cancion["external_urls"]["spotify"] ? mejor_cancion["external_urls"]["spotify"] : "No se pudo conseguir link"


  datos_artistas << {
    nombre: nombre_artista,
    popularidad: popularidad_artista,
    cancion_mas_popular: nombre_cancion,
    preview_url: url_preview
  }
end

# -----------------------------
# Parte 5: Mostrar resultados ordenados por nombre
# -----------------------------
datos_artistas.sort_by { |a| a[:nombre] }.each do |artista|
  puts "Nombre: #{artista[:nombre]}"
  puts "Popularidad: #{artista[:popularidad]}"
  puts "Canción más popular en Chile: #{artista[:cancion_mas_popular]}"
  puts "Preview URL: #{artista[:preview_url]}"
  puts "-" * 40
end

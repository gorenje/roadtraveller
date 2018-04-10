['sinatra/base', 'haml', 'thin', 'base64', 'rest-client', 'yaml'].
  map { |a| require(a) }

class Webapp < Sinatra::Base
  set :show_exceptions, :after_handler

  LinkRegExp = /@([-?[:digit:]\.]+),([-?[:digit:]\.]+).+,([-?[:digit:]\.]+)y.*,([-?[:digit:]\.]+)h.*,([-?[:digit:]\.]+)t.+\!1s(.+)\!2e/

  def datapoints
    body = RestClient.get("https://gist.githubusercontent.com"+
                          "/gorenje/4e98ff32c2e03a7fe442d08f17469399/raw").body
    YAML.load(body)[:data]
  end

  def entries
    datapoints.map do |(name, link)|
      if ( link =~ LinkRegExp )
        panoid = $6.length == 22 ? $6 : "F:#{CGI.escape($6)}"

        { :name  => name,
          :link  => link,
          :id    => panoid,
          :location => {
            :lat => $1.to_f,
            :lng => $2.to_f
          },
          :pov => {
            :heading => $4.to_f,
            :pitch   => $5.to_f - 90
          },
          :zoom => 0
        }
      end
    end.compact
  end

  get '/cities.json' do
    content_type :json
    {
      :data => entries.shuffle
    }.to_json
  end

  get '/' do
    haml :index
  end

  error(404) do
    "Action/Page not supported/found."
  end
end

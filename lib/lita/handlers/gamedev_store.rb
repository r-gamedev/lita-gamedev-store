require 'andand'

module Lita
  module Handlers
    class GamedevStore < Handler

      route(/^!set game\s+(.+)/, :game_set,
            help: {
              '!set game Retro Pixel Castles - http://retropixelcastles.com/ - http://store.steampowered.com/app/328080/' =>
                'sets your game spiel to "Retro Pixel Castles - http://retropixelcastles.com/ - http://store.steampowered.com/app/328080/"',
              '!set game Literally anthing you like. Consider including links.' =>
                'sets your game spiel to "Literally anthing you like. Consider including links."'})

      route(/^!alias game\s+(.+)/, :game_alias,
            help: {
              '!alias game k-hos' =>
                'causes any requests for the game of your current nick to resolve to the k-hos',
              'set game Literally anthing you line. Consider including links.' =>
                'sets your game spiel to "Literally anthing you line. Consider including links."'})

      route(/^!clear game/, :game_clear,
        help: {
          '!clear game' =>
            'clears the game or alias of the current nick'})

      route(/^!game(?:\s+(.+))?/, :game_get,
            help: {
              '!game' =>
                'gets the game spiel of the calling user',
              '!game lemtzas' =>
                'gets the game spiel of lemtzas',
              '!game lemtzas__' =>
                'gets the game spiel of lemtzas__, lemtzas_, or lemtzas (removing underscores)'})

      def game_set(response)
        username = mangle_name response.user.name
        spiel = response.match_data[1]
        redis.set(gamekey(username), spiel)
        response.reply "#{response.user.name}, game spiel set to '#{spiel}'"

        useralias = redis.get(aliaskey(username))
        if redis.get(aliaskey(username))
          response.reply "#{response.user.name}, cleared alias '#{useralias}'"
          redis.del(aliaskey(username))
        end
      end

      def game_alias(response)
        username = mangle_name response.user.name
        useralias = mangle_name response.match_data[1]
        redis.set(aliaskey(username), useralias)
        response.reply "#{response.user.name}, created alias #{username} => useralias"

        spiel = redis.get(gamekey(username))
        if spiel
          response.reply "#{response.user.name}, cleared game spiel '#{spiel}'"
          redis.del(gamekey(username))
        end
      end

      def game_clear(response)
        username = mangle_name response.user.name
        useralias = redis.get(aliaskey(username))
        spiel = redis.get(gamekey(username))
        redis.del(aliaskey(username))
        redis.del(gamekey(username))
        if !(useralias || spiel)
          response.reply "#{response.user.name}, nothing to clear"
        elsif useralias && spiel
          response.reply "#{response.user.name}, cleared alias '#{useralias}' and game spiel '#{spiel}'"
        elsif useralias
          response.reply "#{response.user.name}, cleared alias '#{useralias}'"
        else
          response.reply "#{response.user.name}, cleared game spiel '#{spiel}'"
        end
      end

      def game_get(response)
        self_target = !response.match_data[1]
        target = response.match_data[1] || response.user.name
        chain = [response.user.name]
        loop do
          useralias = redis.get(aliaskey(chain.last))
          break unless useralias
          chain << useralias
        end
        username = mangle_name chain.last
        spiel = redis.get(gamekey(username))
        if spiel
          if self_target
            response.reply "#{response.user.name}, your game spiel: #{spiel}"
          else
            response.reply "#{response.user.name}, #{username}'s game spiel: #{spiel}"
          end
        else
          path = chain.join(' => ')
          response.reply "#{response.user.name}, no game spiel found. alias chain: #{path}"
        end
      end

      def mangle_name(username)
        username.gsub(/_+$/, '') || '_'
      end

      def gamekey(username)
        username = mangle_name username.downcase
        "game=#{username}"
      end

      def aliaskey(username)
        username = mangle_name username.downcase
        "alias=#{username}"
      end

      Lita.register_handler(self)
    end
  end
end

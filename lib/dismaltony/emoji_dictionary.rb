module DismalTony
  class EmojiDictionary
    @emoji_array = {
        '0' => '0️⃣',
        '1' => '1️⃣',
        '10' => '🔟',
        '100' => '💯',
        '2' => '2️⃣',
        '3' => '3️⃣',
        '4' => '4️⃣',
        '5' => '5️⃣',
        '6' => '6️⃣',
        '7' => '7️⃣',
        '8' => '8️⃣',
        '9' => '9️⃣',
        'alarmbell' => '🔔',
        'alarmclock' => '⏰',
        'americanflag' => '🇺🇸',
        'anchor' => '⚓️',
        'angry' => '😡',
        'beer' => '🍺',
        'birthdaycake' => '🎂',
        'bolt' => '⚡️',
        'bomb' => '💣',
        'burger' => '🍔',
        'bus' => '🚌',
        'calendar' => '📅',
        'camera' => '📷',
        'cancel' => '🚫',
        'car' => '🚗',
        'cat' => '😺',
        'caution' => '⚠️',
        'chartdown' => '📉',
        'chartup' => '📈',
        'checkbox' => '✅',
        'cheeky' => '😜',
        'chili' => '🌶',
        'clockface' => '🕓',
        'coffee' => '☕️',
        'cookie' => '🍪', 
        'cool' => '😎',
        'creditcard' => '💳',
        'crystalball' => '🔮',
        'dice' => '🎲',
        'dog' => '🐶',
        'egg' => '🍳',
        'envelope' => '✉️',
        'envelopearrow' => '📩',
        'envelopeheart' => '💌',
        'exclamationmark' => '❗️',
        'fire' => '🔥',
        'fish' => '🐠',
        'flower' => '🌺',
        'fries' => '🍟',
        'frown' => '🙁',
        'game' => '🎮',
        'gate' => '🚧',
        'gem' => '💎',
        'hourglass' => '⏳',
        'key' => '🔑',
        'knifefork' => '🍴',
        'laptop' => '💻',
        'lock' => '🔒',
        'magnifyingglass' => '🔎',
        'mailbox' => '📫',
        'martini' => '🍸',
        'medal' => '🏅',
        'megaphone' => '📢',
        'moneybag' => '💰',
        'moneywing' => '💸',
        'moon' => '🌙',
        'moviecamera' => '📽',
        'nobell' => '🔕',
        'octo' => '🐙',
        'package' => '📦',
        'pencil' => '✏️',
        'phone' => '📞',
        'pickaxe' => '⛏',
        'pill' => '💊',
        'pineapple' => '🍍',
        'pizza' => '🍕',
        'popcorn' => '🍿',
        'pound' => '#️⃣',
        'present' => '🎁',
        'questionmark' => '❓',
        'raincloud' => '🌧',
        'rocket' => '🚀',
        'scroll' => '📜',
        'shower' => '🚿',
        'siren' => '🚨',
        'sleepy' => '😴',
        'sly' => '😏',
        'smile' => '🙂',
        'snail' => '🐌',
        'snake' => '🐍',
        'snowflake' => '❄️',
        'spaceinvader' => '👾',
        'speechbubble' => '💬',
        'star' => '⭐️',
        'stopwatch' => '⏱',
        'sun' => '☀️',
        'taco' => '🌮',
        'thebird' => '🖕',
        'thermometer' => '🌡',
        'think' => '🤔',
        'thumbsdown' => '👎',
        'thumbsup' => '👍',
        'ticket' => '🎟',
        'tophat' => '🎩',
        'trophy' => '🏆',
        'tropicaldrink' => '🍹',
        'tv' => '📺',
        'unlock' => '🔓',
        'wave' => '👋',
        'wink' => '😉',
        'worried' => '🤕',
        'zzz' => '💤'   
      }
    class << self; attr_accessor :emoji_array end
    def self.[](search)
        emoji_array[search]
    end

    def self.to_h
        emoji_array
    end

    def self.name(moj)
        @emoji_array.key(moj) || "emoji"
    end
  end
end

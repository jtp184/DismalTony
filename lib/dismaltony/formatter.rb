module DismalTony # :nodoc:
  # Responsible for taking strings and formatting them according to project guidelines
  module Formatter
    # a Regexp which matches a message sent with the standard DismalTony format
    OUTGOING = /(?<label>\[(?<moji>.+)\]\: )(?<message>.+)/.freeze
    # a Regexp which matches a message string, and includes support for extracting the emoji signifier
    INCOMING = /(?:~e:(?<emote>\w+\b) )?(?<message>(.|\s)+)/.freeze

    # The main function of the module. Parses +opts+ to determine what transformations to apply to +str+ before returning it
    def self.format(str, opts = {})
      md = Formatter::INCOMING.match(str)
      em = (md['emote'] || 'smile')

      result = md['message']

      em = get_icon(em)
      em = opts[:use_icon] if opts[:use_icon]

      result = Formatter.add_icon(result, em) unless opts[:icon] == false
      result = extra_space(result) if opts[:extra_space]
      result
    end

    # Gets an emoji from its internal name.
    def self.get_icon(emo)
      emoji_dictionary[emo]
    end

    class << self
      alias emoji get_icon
    end

    # Inverse lookup on the emoji table
    def emoji_name(moj)
      emoji_dictionary.key(moj)
    end

    # Takes +str+ and an emoji +emo+ and creates a standard formatted string
    def self.add_icon(str, emo)
      "[#{emo}]: #{str}"
    end

    # Uses String#gsub to pad +str+ with extra space before a closing
    # square bracket, allowing the default text output to work in terminal.
    def self.extra_space(str)
      str.gsub(/]:/, '  ]:')
    end
  end

  module Formatter # :nodoc:
    def self.emoji_dictionary
      {
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
        'airplane' => '✈️',
        'alarmbell' => '🔔',
        'alarmclock' => '⏰',
        'americanflag' => '🇺🇸',
        'anchor' => '⚓️',
        'angry' => '😡',
        'barchart' => '📊',
        'beer' => '🍺',
        'bicycle' => '🚲',
        'birthdaycake' => '🎂',
        'bolt' => '⚡️',
        'bomb' => '💣',
        'brain' => '🧠',
        'brokenhome' => '🏚',
        'burger' => '🍔',
        'burrito' => '🌯',
        'bus' => '🚌',
        'calendar' => '📅',
        'camera' => '📷',
        'cancel' => '🚫',
        'car' => '🚗',
        'cat' => '😺',
        'caution' => '⚠️',
        'champagne' => '🍾',
        'chartdown' => '📉',
        'chartup' => '📈',
        'checkbox' => '✅',
        'cheeky' => '😜',
        'cheers' => '🍻',
        'chili' => '🌶',
        'cigarette' => '🚬',
        'clockface' => '🕓',
        'coffee' => '☕️',
        'computer' => '🖥',
        'cookie' => '🍪',
        'cool' => '🆒',
        'creditcard' => '💳',
        'crystalball' => '🔮',
        'dice' => '🎲',
        'dog' => '🐶',
        'dollarsign' => '💲',
        'doughnut' => '🍩',
        'egg' => '🍳',
        'envelope' => '✉️',
        'envelopearrow' => '📩',
        'envelopeheart' => '💌',
        'exclamationmark' => '❗️',
        'fire' => '🔥',
        'fish' => '🐠',
        'flower' => '🌺',
        'free' => '🆓',
        'fries' => '🍟',
        'frown' => '🙁',
        'game' => '🎮',
        'gate' => '🚧',
        'gem' => '💎',
        'genie' => '🧞‍♂️',
        'globe' => '🌎',
        'goofy' => '🤪',
        'gust' => '💨',
        'home' => '🏠',
        'hourglass' => '⏳',
        'key' => '🔑',
        'knifefork' => '🍴',
        'laptop' => '💻',
        'lightbulb' => '💡',
        'lock' => '🔒',
        'magnifyingglass' => '🔎',
        'mailbox' => '📫',
        'mappin' => '📍',
        'martini' => '🍸',
        'medal' => '🏅',
        'megaphone' => '📢',
        'mindblown' => '🤯',
        'moai' => '🗿',
        'moneybag' => '💰',
        'moneywing' => '💸',
        'monocle' => '🧐',
        'moon' => '🌙',
        'moviecamera' => '📽',
        'new' => '🆕',
        'nobell' => '🔕',
        'nosmoking' => '🚭',
        'ocean' => '🌊',
        'octo' => '🐙',
        'ok' => '🆗',
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
        'rainbow' => '🌈',
        'raincloud' => '🌧',
        'rocket' => '🚀',
        'sandwich' => '🥪',
        'scroll' => '📜',
        'shower' => '🚿',
        'shush' => '🤫',
        'siren' => '🚨',
        'sleepy' => '😴',
        'sly' => '😏',
        'smile' => '🙂',
        'snail' => '🐌',
        'snake' => '🐍',
        'snowflake' => '❄️',
        'snowman' => '☃️',
        'spaceinvader' => '👾',
        'speechbubble' => '💬',
        'star' => '⭐️',
        'stareyes' => '🤩',
        'stopwatch' => '⏱',
        'sun' => '☀️',
        'sunglasses' => '😎',
        'taco' => '🌮',
        'takeout' => '🥡',
        'thebird' => '🖕',
        'thermometer' => '🌡',
        'think' => '🤔',
        'thumbsdown' => '👎',
        'thumbsup' => '👍',
        'ticket' => '🎟',
        'toast' => '🥂',
        'tophat' => '🎩',
        'tornado' => '🌪',
        'trophy' => '🏆',
        'tropicaldrink' => '🍹',
        'tv' => '📺',
        'umbrella' => '☂️',
        'umbrellarain' => '☔️',
        'unlock' => '🔓',
        'up' => '🆙',
        'volcano' => '🌋',
        'vomit' => '🤮',
        'watch' => '⌚️',
        'waterdrop' => '💧',
        'waterdrops' => '💦',
        'wave' => '👋',
        'whiskey' => '🥃',
        'windblow' => '🌬',
        'wineglass' => '🍷',
        'wink' => '😉',
        'worldmap' => '🗺️',
        'worried' => '🤕',
        'zzz' => '💤'
      }
    end
  end
end

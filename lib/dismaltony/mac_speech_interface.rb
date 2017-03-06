module DismalTony
	class MacSpeechInterface < DialogInterface
		def send(msg)
			if msg =~ DismalTony::Formatter::Printer::OUTGOING
				md = DismalTony::Formatter::Printer::OUTGOING.match msg
				emote = md['moji']
				text = md['message']
				`say #{DismalTony::EmojiDictionary.name(emote)}. #{text}`
			else
				`say #{msg}`
			end
		end
	end
end
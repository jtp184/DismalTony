DismalTony.create_handler do
  @handler_name = 'cthulhu-character'
  @patterns = [/generate a call of cthulhu character/i]

  def activate_handler(_query, _user)
    "I'll generate a Call of Cthulhu character!"
  end

  def activate_handler!(query, user)
    result = "~e:magnifyingglass Here's your Investigator!\n"
    chargen(query, user).each_pair do |key, val|
      result << "\s\s\s#{key.upcase}: #{val}\n"
    end
    DismalTony::HandledResponse.finish result
  end

  def chargen(_query, user)
    stats = {}
    stats['str'] = @vi.query_result!('Roll 3D6', user).first.first
    stats['con'] = @vi.query_result!('Roll 3D6', user).first.first
    stats['pow'] = @vi.query_result!('Roll 3D6', user).first.first
    stats['dex'] = @vi.query_result!('Roll 3D6', user).first.first
    stats['app'] = @vi.query_result!('Roll 3D6', user).first.first

    stats['siz'] = @vi.query_result!('Roll 2D6+6', user).first.first
    stats['int'] = @vi.query_result!('Roll 2D6+6', user).first.first

    stats['edu'] = @vi.query_result!('Roll 3D6+3', user).first.first

    stats['san'] = stats['pow'] * 5

    stats['idea'] = stats['int'] * 5
    stats['luck'] = stats['pow'] * 5
    stats['know'] = stats['edu'] * 5

    stats['db'] = case (stats['str'] + stats['siz'])
                  when (2..12)
                    '-1d6'
                  when (13..16)
                    '-1d4'
                  when (17..24)
                    '0'
                  when (25..32)
                    '+1d4'
                  when (33..40)
                    '+1d6'
                  when (41..56)
                    '+2d6'
                  when (57..72)
                    '+3d6'
                  when (73..88)
                    '+4d6'
    end

    stats['hp'] = ((stats['con'] + stats['siz']) / 2).ceil
    stats['mp'] = stats['pow']
    stats['money'] = case @vi.query_result!('Roll 1d10').first.first
                     when 1
                       '$1500'
                     when 2
                       '$2500'
                     when 3, 4
                       '$3500'
                     when 5
                       '$4500'
                     when 6
                       '$5500'
                     when 7
                       '$6500'
                     when 8
                       '$7500'
                     when 9
                       '$10,000'
                     when 10
                       '$20,000'
   end
    stats
 end
end

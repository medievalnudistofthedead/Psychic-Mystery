def pbDARKPokemonMart(stock, speech = nil, cantsell = false)
  stock.delete_if { |item| GameData::Item.get(item).is_important? && $bag.has?(item) }
  commands = []
  cmdBuy  = -1
  cmdSell = -1
  cmdQuit = -1
  commands[cmdBuy = commands.length]  = _INTL("I'm here to buy")
  commands[cmdSell = commands.length] = _INTL("I'm here to sell") if !cantsell
  commands[cmdQuit = commands.length] = _INTL("No, thanks")
  cmd = pbMessage(speech || _INTL("..."), commands, cmdQuit + 1)
  loop do
    if cmdBuy >= 0 && cmd == cmdBuy
      scene = PokemonMart_Scene.new
      screen = PokemonMartScreen.new(scene, stock)
      screen.pbBuyScreen
    elsif cmdSell >= 0 && cmd == cmdSell
      scene = PokemonMart_Scene.new
      screen = PokemonMartScreen.new(scene, stock)
      screen.pbSellScreen
    else
      pbMessage(_INTL("..."))
      break
    end
    cmd = pbMessage(_INTL("..."), commands, cmdQuit + 1)
  end
  $game_temp.clear_mart_prices
end

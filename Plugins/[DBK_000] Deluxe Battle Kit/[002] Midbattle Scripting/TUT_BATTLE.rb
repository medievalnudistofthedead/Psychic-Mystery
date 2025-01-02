#-----------------------------------------------------------------------------
# Tutorial Battle created by Medi
#-----------------------------------------------------------------------------
module MidbattleScripts
  TUT_BATTLE = {
    "RoundStartCommand_1_player" => "I'll now show you how to catch a Pokemon.",
    "BeforeDamagingMove_player" => ["Weakening a Pokémon through battle makes them much easier to catch!",
                                    "Be careful though - you don't want to knock them out completely!\nYou'll lose your chance if you do!",
                                    "Let's try dealing some damage.\nGet 'em, {1}!"],
    "BattlerStatusChange_foe" => [:Opposing, "It's always a good idea to inflict status conditions like Sleep or Paralysis!",
                                    "This will really help improve your odds at capturing the Pokémon!"],									
    "TurnStart_player" => {
        "useMove"      => [:THUNDERWAVE],
        "setBattler"   => :Opposing,
        "battlerHPCap" => -1
    },
    "RoundEnd_player_repeat" => {
        "ignoreUntil" => ["TargetTookDamage_foe", "RoundEnd_player_2"],
        "speech_A"    => "The Pokémon is weak!\nNow's the time to throw a Poké Ball!",
        "useItem"     => :POKEBALL,
        "speech_B"    => "Alright, that's how it's done!"
	}
}
end
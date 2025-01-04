#===============================================================================
# Plugin: Randomized Ground Items
# Author: Medi
# Version: 1.0 (Optimized)
# Description: This plugin randomizes ground items based on a predefined pool.
#===============================================================================
module ItemRandomizer
  CONFIG_FILE = "Plugins/Randomized Ground Items/area_item_pools.txt"

  # Store the loaded area pools
  @area_pools = {}

  # Load the configuration file
  def self.load_pools
    return unless File.exist?(CONFIG_FILE)

    File.foreach(CONFIG_FILE) do |line|
      line = line.strip
      next if line.empty? || line.start_with?("#") # Skip blank lines and comments

      key, items = line.split(":", 2)
      next unless key && items

      map_id = key.to_i
      @area_pools[map_id] = items.split(",").map { |item| item.strip.to_sym }
    end
  end

  # Save the current pools to the configuration file
  def self.save_pools
    File.open(CONFIG_FILE, "w") do |file|
      @area_pools.each { |key, items| file.puts "#{key}: #{items.join(', ')}" }
    end
  end

  # Get a random item for a given area
  def self.random_item(area)
    pool = @area_pools[area]
    pool&.sample
  end

  # Dynamically modify item pools
  def self.set_pool(area, items)
    @area_pools[area] = items.map(&:to_sym)
    save_pools
  end

  # Delete a pool
  def self.delete_pool(area)
    @area_pools.delete(area)
    save_pools
  end

  # Debug: Get the current pool
  def self.get_pool(area)
    @area_pools[area] || []
  end

  # Retrieve all existing map IDs
  def self.existing_map_ids
    @area_pools.keys.sort
  end
end

# Automatically load pools at startup
ItemRandomizer.load_pools

class Interpreter
  # Randomized item ball
  def pbRandomizedItemBall(quantity = 1)
    area = $game_map.map_id
    randomized_item = ItemRandomizer.random_item(area) || :POTION
    pbItemBall(randomized_item, quantity)
  end
end

#===============================================================================
# Add Debug Menu Commands
#===============================================================================
if defined?(MenuHandlers)
  MenuHandlers.add(:debug_menu, :randomized_items_menu, {
    "name"        => _INTL("Randomized Items"),
    "parent"      => :main,
    "description" => _INTL("Modify item pools for randomized ground items."),
    "always_show" => true
  })

  MenuHandlers.add(:debug_menu, :modify_item_pools, {
    "name"        => _INTL("Modify item pools..."),
    "parent"      => :randomized_items_menu,
    "description" => _INTL("Edit item pools for specific areas."),
    "effect"      => proc {
      existing_map_ids = ItemRandomizer.existing_map_ids
      options = existing_map_ids.map(&:to_s) + [_INTL("Create New Pool")]

      choice = pbShowCommands(nil, options, -1)
      next if choice < 0

      area_id = if choice == existing_map_ids.size
                  input_map_id(existing_map_ids)
                else
                  existing_map_ids[choice]
                end
      next unless area_id

      modify_pool(area_id)
    }
  })

  MenuHandlers.add(:debug_menu, :delete_item_pools, {
    "name"        => _INTL("Delete item pools..."),
    "parent"      => :randomized_items_menu,
    "description" => _INTL("Delete item pools for specific areas."),
    "effect"      => proc {
      existing_map_ids = ItemRandomizer.existing_map_ids
      next if existing_map_ids.empty?

      choice = pbShowCommands(nil, existing_map_ids.map(&:to_s), -1)
      next if choice < 0

      area_id = existing_map_ids[choice]
      next unless pbConfirmMessage(_INTL("Are you sure you want to delete the pool for Map ID {1}?", area_id))

      ItemRandomizer.delete_pool(area_id)
      pbMessage(_INTL("Deleted pool for Map ID {1}.", area_id))
    }
  })
end

#===============================================================================
# Helper Functions
#===============================================================================
def input_map_id(existing_map_ids)
  map_id = pbMessageFreeText(_INTL("Enter a new Map ID:"), "", false, 5, Graphics.width).to_i
  map_infos = pbLoadMapInfos
  if !map_infos.has_key?(map_id)
    pbMessage(_INTL("Error: Map ID {1} does not exist.", map_id))
    return nil
  elsif existing_map_ids.include?(map_id)
    pbMessage(_INTL("Map ID {1} already exists.", map_id))
    return nil
  end
  map_id
end

def modify_pool(area_id)
  current_pool = ItemRandomizer.get_pool(area_id)
  pool_display = current_pool.empty? ? "No items in pool." : current_pool.join(", ")
  new_items_input = pbMessageFreeText(
    _INTL("Current pool: {1}. Enter new items (comma-separated):", pool_display),
    current_pool.join(", "),
    false, 256, Graphics.width
  )
  return if new_items_input.nil? || new_items_input.strip.empty?

  new_items = new_items_input.split(",").map(&:strip)
  invalid_items = new_items.reject { |item| GameData::Item.exists?(item.to_sym) }
  if invalid_items.any?
    pbMessage(_INTL("Error: Invalid items detected: {1}.", invalid_items.join(", ")))
    return
  end

  ItemRandomizer.set_pool(area_id, new_items)
  pbMessage(_INTL("Updated pool for Map ID {1} to: {2}.", area_id, new_items.join(", ")))
end

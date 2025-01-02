#===============================================================================
# Plugin: Randomized Ground Items (AI Generated)
# Author: Medi
# Version: 1.
# Description: This plugin randomizes ground items based on a predefined pool.
#===============================================================================
module ItemRandomizer
  # Path to the configuration file
  CONFIG_FILE = "Plugins/Randomized Ground Items/area_item_pools.txt"

  # Store the loaded area pools
  @area_pools = {}

  # Load the configuration file
  def self.load_pools
    if File.exist?(CONFIG_FILE)
      File.readlines(CONFIG_FILE).each do |line|
        next if line.strip.empty? || line.strip.start_with?("#") # Skip blank lines and comments
        key, items = line.strip.split(":", 2)
        if key && items
          key = key.strip.to_i # Use map ID as the key
          items = items.strip.split(",").map(&:strip).map(&:to_sym) # Convert items to symbols
          @area_pools[key] = items
        end
      end
    else
      raise "ItemRandomizer: Configuration file not found at #{CONFIG_FILE}"
    end
  end

  # Save the current pools to the configuration file
  def self.save_pools
    File.open(CONFIG_FILE, "w") do |file|
      @area_pools.each do |key, items|
        file.puts "#{key}: #{items.join(", ")}"
      end
    end
  end

  # Get a random item for a given area
  def self.random_item(area)
    pool = @area_pools[area] || []
    return pool.sample if pool.any?
    return nil # Return nil if no pool exists for the area
  end

  # Method to add or modify a pool dynamically
  def self.set_pool(area, items)
    @area_pools[area] = items.map(&:to_sym)
    save_pools # Save changes to the file
  end

  # Method to delete a pool
  def self.delete_pool(area)
    @area_pools.delete(area)
    save_pools # Save changes to the file
  end

  # Method to get the current pool for debugging
  def self.get_pool(area)
    @area_pools[area] || []
  end

  # Method to retrieve all existing map IDs
  def self.existing_map_ids
    @area_pools.keys.sort
  end
end

# Automatically load the pools when the plugin is loaded
ItemRandomizer.load_pools

class Interpreter
  # Custom method to randomize ground items
  def pbRandomizedItemBall(quantity = 1)
    # Use map ID as the area identifier
    area = $game_map.map_id
    randomized_item = ItemRandomizer.random_item(area) || :POTION # Default item if no pool
    pbItemBall(randomized_item, quantity)
  end
end

#===============================================================================
# Add Debug Menu Commands
#===============================================================================

if defined?(MenuHandlers)
  # Adding Randomized Items option to Debug Menu
  MenuHandlers.add(:debug_menu, :randomized_items_menu, {
    "name"        => _INTL("Randomized Items"),
    "parent"      => :main,
    "description" => _INTL("Modify item pools for randomized ground items."),
    "always_show" => true
  })

# Option to modify item pools
MenuHandlers.add(:debug_menu, :modify_item_pools, {
  "name"        => _INTL("Modify item pools..."),
  "parent"      => :randomized_items_menu,
  "description" => _INTL("Edit the item pools for specific areas."),
  "effect"      => proc {
    # Retrieve existing map IDs
    existing_map_ids = ItemRandomizer.existing_map_ids
    map_options = existing_map_ids.map(&:to_s) + [_INTL("Create New Pool")]

    # Display the selection menu
    choice = pbShowCommands(nil, map_options, -1)
    next if choice < 0 # Cancelled

    if choice == existing_map_ids.size
      # User selected "Create New Pool"
      new_map_prompt = _INTL("Enter a new Map ID:")
      new_map_id_input = pbMessageFreeText(new_map_prompt, "", false, 5, Graphics.width)
      next if new_map_id_input.nil? || new_map_id_input.strip.empty?

      area_id = new_map_id_input.to_i

      # Check if the Map ID exists in the database
      map_infos = pbLoadMapInfos
      if !map_infos.has_key?(area_id)
        pbMessage(_INTL("Error: Map ID {1} does not exist in the database. Please enter a valid Map ID.", area_id))
        next
      end

      if existing_map_ids.include?(area_id)
        pbMessage(_INTL("Map ID {1} already exists.", area_id))
        next
      end
    else
      # User selected an existing Map ID
      area_id = existing_map_ids[choice]
    end

    # List the current pool for the selected area
    current_pool = ItemRandomizer.get_pool(area_id)
    pool_display = current_pool.empty? ? "No items in pool." : current_pool.join(", ")

    # Ask user to enter new items (comma-separated)
    new_items_prompt = _INTL("Current pool: {1}. Enter new items (comma-separated):", pool_display)
    default_items = current_pool.join(", ")
    new_items_input = pbMessageFreeText(new_items_prompt, default_items, false, 256, Graphics.width)

    # If no input was provided, exit
    next if new_items_input.nil? || new_items_input.strip.empty?

    # Validate the entered items
    item_list = new_items_input.split(",").map(&:strip)
    invalid_items = item_list.reject { |item| GameData::Item.exists?(item.to_sym) }

    if invalid_items.any?
      pbMessage("Error: Invalid items detected: #{invalid_items.join(', ')}. Please enter valid item names.")
      next
    end

    # Update the pool
    ItemRandomizer.set_pool(area_id, item_list)
    pbMessage("Updated pool for Map ID #{area_id} to: #{item_list.join(", ")}")
  }
})


  # Option to delete item pools
  MenuHandlers.add(:debug_menu, :delete_item_pools, {
    "name"        => _INTL("Delete item pools..."),
    "parent"      => :randomized_items_menu,
    "description" => _INTL("Delete item pools for specific areas."),
    "effect"      => proc {
      # Retrieve existing map IDs
      existing_map_ids = ItemRandomizer.existing_map_ids
      next if existing_map_ids.empty?

      # Display the selection menu
      choice = pbShowCommands(nil, existing_map_ids.map(&:to_s), -1)
      next if choice < 0 # Cancelled

      # Confirm deletion
      area_id = existing_map_ids[choice]
      confirm = pbConfirmMessage(_INTL("Are you sure you want to delete the pool for Map ID {1}?", area_id))
      next unless confirm

      # Delete the pool
      ItemRandomizer.delete_pool(area_id)
      pbMessage("Deleted pool for Map ID #{area_id}.")
    }
  })
end

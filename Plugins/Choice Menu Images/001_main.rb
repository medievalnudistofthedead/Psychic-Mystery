#--------------------------------------------------#
#=============Choice Menu Images===================#
#==============made by PaperKing===================#
#---------------------------------------------------

# This plugin was created as an accessory and an enhancement to the original Show Choices menu offered by Essentials. It will apply images to
# each dialogue option, which will appear when that option is highlighted. This can be used in many ways, such as selecting a Pokemon, selecting items,
# or my main purpose of using it, having a Character Portrait system that shows the character's emotions behind the decisions they make. It has many
# uses, and I look forward to seeing how this will be used creatively! Currently supported by v21.1 and v20.1, but shouldn't be hard to make backwards
# compatible if necessary. This is my very first plugin, so BE NICE :) jk hope you guys enjoy!

module ChoiceHoverImages
  @hover_images = []

  def self.set_hover_images(images)
    @hover_images = images
  end

  def self.hover_images
    @hover_images
  end

  def self.clear_hover_images
    @hover_images.clear
  end
end

class Window_CommandPokemon
  alias original_initialize initialize
  alias original_update update

  def initialize(commands, width = 198)
    original_initialize(commands, width)
    create_hover_sprite
    @current_image_path = nil
  end

  def create_hover_sprite
    @hover_sprite = Sprite.new
    @hover_sprite.bitmap = nil
    @hover_sprite.z = 100  
    @hover_sprite.visible = false  # Start hidden
  end

  def update
    original_update

    return unless self.active && self.visible
    create_hover_sprite if @hover_sprite.nil?

    hovered_index = self.index
    image_path = ChoiceHoverImages.hover_images[hovered_index]

	# If there's no image for this choice (image_path is nil), hide the hover sprite
    if image_path.nil?
      @hover_sprite.visible = false
	  #Valuable information - I am not good at coding at all LMAO. if you want to have a choice menu where some of the options don't have images...
	  #I've included a blank image in "Graphics/Plugins/Choice Menu Images/blank.png" .
    else
      # Load and display the image for this choice if it exists
      begin
        bitmap = Bitmap.new(image_path)
        if bitmap
          @hover_sprite.bitmap&.dispose
          @hover_sprite.bitmap = bitmap
          @current_image_path = image_path
          @hover_sprite.visible = true
        end
      rescue => e
        puts "Error loading image: #{e.message}"
        @hover_sprite.visible = false
      end
    end

    # Sprite Positioning
    if @hover_sprite.bitmap
      # Depending on the size of your image, you may need to adjust this for it to look clean. These numbers below fit my 110x104 portrait images for Project Evolution.
      @hover_sprite.x = self.x - @hover_sprite.bitmap.width - 15
      @hover_sprite.y = 182
    else
      @hover_sprite.visible = false
    end
  end

  def dispose
    super
    @hover_sprite.bitmap.dispose if @hover_sprite&.bitmap
    @hover_sprite.dispose if @hover_sprite
  end
end

# HOW TO USE THIS CODE IN YOUR EVENT COMMANDS!

# Ensure that your "Show Text" and "Show Choices" commands are next to each other to ensure that this menu functions properly. If you try to put
# the definition in between "Show Text" and "Show Choices" the player will be required to perform an additional input to access the menu, which
# also closes the initial "Show Text" box. I like to define my choices at the very beginning! Or if multiple choice menus will be called, define
# them right at the end of the previous one. ALWAYS use the "ChoiceHoverImages.clear_hover_images" event script when you are finished with your
# choice menu, so that these images do not leak into other choice menus(Even the pause menu!!)

#Example Event:

#--------------------------------------------------------------------------------
# ChoiceHoverImages.set_hover_images([
# "Graphics/Plugins/Choice Menu Images/yes-image.png",  # Image for choice 1
# "Graphics/Plugins/Choice Menu Images/no-image.png"  # Image for choice 2
#])
#@>Show Text: \rDo you think I look nice today?
#@>Show Choices: Yes, No

#logic for choices...

#ChoiceHoverImages.clear_hover_images
#--------------------------------------------------------------------------------
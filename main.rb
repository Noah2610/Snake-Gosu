
require 'gosu'

$screen = {
	width: 460,
	height: 460
}
$grid_size = 24
$grid = {
	width: ($screen[:width] / $grid_size).to_i,
	height: ($screen[:height] / $grid_size).to_i
}
$controls = {
	up: [Gosu::KB_W, Gosu::KB_UP, Gosu::KB_K],
	down: [Gosu::KB_S, Gosu::KB_DOWN, Gosu::KB_J],
	left: [Gosu::KB_A, Gosu::KB_LEFT, Gosu::KB_H],
	right: [Gosu::KB_D, Gosu::KB_RIGHT, Gosu::KB_L]
}
$score = 0
$max_foods = 5
$game_speed = 250
$food_spawn_chance = (0..4)


class Integer
	def is_key? (arr)
		return arr.map { |k| next true  if (self == k); next false }.include? true
	end
end

# credit:
# https://stackoverflow.com/questions/15738336/ruby-array-reverse-each-with-index
class Array
	def reverse_each_with_index &block
		(0...length).reverse_each do |i|
			block.call self[i], i
		end
	end
end


class Snake
	attr_accessor :x, :y, :mv_dir, :body

	def initialize
		#@x = ($screen[:width] / 2).to_i
		#@y = ($screen[:height] / 2).to_i
		@x = ($grid[:width] / 2).to_i
		@y = ($grid[:height] / 2).to_i
		@size = $grid_size
		@color_head = Gosu::Color.argb(0xff_0000ff)
		@color_body = Gosu::Color.argb(0xff_00ffff)
		@mv_dir = { x: 1, y: 0 }
		@body = [
			{ x: (@x - 1), y: @y },
			{ x: (@x - 2), y: @y },
			{ x: (@x - 3), y: @y }
		]
	end

	def move
		return  unless $game_running

		# move body parts
		@body.reverse_each_with_index do |b,i|
			if (i > 0)
				b[:x] = @body[i - 1][:x]
				b[:y] = @body[i - 1][:y]
			elsif (i == 0)
				b[:x] = @x
				b[:y] = @y
			end
		end
		# move head
		@x += @mv_dir[:x]
		@y += @mv_dir[:y]

		# loop around if offscreen
		if (@x > $grid[:width] - 1)
			@x = 0
		elsif (@x < 0)
			@x = $grid[:width] - 1
		end
		if (@y > $grid[:height] - 1)
			@y = 0
		elsif (@y < 0)
			@y = $grid[:height] - 1
		end

		# check collision with body part
		@body.each do |b|
			if (@x == b[:x] && @y == b[:y])
				$game_running = false
				$game_over = true
			end
		end
	end
	
	def draw
		# draw body parts
		@body.each do |b|
			Gosu.draw_rect(b[:x] * $grid_size, b[:y] * $grid_size, @size,@size, @color_body)
		end
		# draw head
		Gosu.draw_rect(@x * $grid_size, @y * $grid_size, @size,@size, @color_head)
	end
end


class Food
	def initialize
		not_valid = true
		while (not_valid) do
			not_valid = false
			@x = rand(1...$grid[:width]).to_i
			@y = rand(1...$grid[:height]).to_i
			if (@x == $game.snake.x && @y == $game.snake.y)
				not_valid = true
			end
			$game.snake.body.each do |b|
				if (@x == b[:x] && @y == b[:y])
					not_valid = true
				end
			end
			if (not_valid)
				next
			end
		end
		@size = ($grid_size / 2).to_i
		@color = Gosu::Color.argb(0xff_ff0000)
	end

	def collision_check
		if (@x == $game.snake.x && @y == $game.snake.y)
			# add to snake body part and remove self
			$game.snake.body.push $game.snake.body[-1].dup
			$game.foods.delete self
			$score += 10
		end
	end

	def draw
		Gosu.draw_rect(@x * $grid_size + @size / 2, @y * $grid_size + @size / 2, @size,@size, @color)
	end
end


class Game < Gosu::Window
	attr_accessor :snake, :foods

	def initialize
		super $screen[:width], $screen[:height]
		self.caption = "Gosu Snake"
		self.update_interval = $game_speed
		@snake = Snake.new
		@foods = []
		@text = Gosu::Font.new 32
	end

	def button_down (id)
		# close window with 'q' key
		close  if (id == Gosu::KB_Q)

		return  unless $game_running

		# snake movement
		if (id.is_key? $controls[:up])        # up
			@snake.mv_dir = { x: 0, y: -1 }  unless (@snake.mv_dir == { x: 0, y: 1 })
		elsif (id.is_key? $controls[:down])   # down
			@snake.mv_dir = { x: 0, y: 1 }   unless (@snake.mv_dir == { x: 0, y: -1 })
		elsif (id.is_key? $controls[:left])   # left
			@snake.mv_dir = { x: -1, y: 0 }  unless (@snake.mv_dir == { x: 1, y: 0 })
		elsif (id.is_key? $controls[:right])  # right
			@snake.mv_dir = { x: 1, y: 0 }   unless (@snake.mv_dir == { x: -1, y: 0 })
		end
	end

	def update

		if (@foods.length < $max_foods)
			@foods.push Food.new  if (rand($food_spawn_chance) == 0)
		end  if ($game_running)

		@foods.each do |food|
			food.collision_check
		end
		@snake.move
	end

	def draw
		# draw score
		@text.draw("Score: #{$score.to_s}", 16, 16, 10)
		@text.draw("Length: #{@snake.body.length + 1}", 16, 42, 10)

		@foods.each do |food|
			food.draw
		end
		@snake.draw

		# draw game over text
		if ($game_over)
			@text.draw_rel("Game Over", $screen[:width] / 2, $screen[:height] / 2 - 80, 10, 0.5, 0.0, 3,3, Gosu::Color.argb(0xff_ff6600))
			@text.draw_rel("Final Score: #{$score}", $screen[:width] / 2, $screen[:height] / 2 + 80, 10, 0.5, 1.0, 2,2, Gosu::Color.argb(0xff_00ff00))
		end
	end
end

$game_over = false
$game_running = true
$game = Game.new
$game.show


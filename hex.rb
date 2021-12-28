MAX_X = 15
MAX_Y = 17

MAX_LEVEL=3

require 'set'

class Hex
  attr_accessor :map
  attr_accessor :x
  attr_accessor :y
  attr_accessor :level
  attr_accessor :has_road
  attr_accessor :road_type
  attr_accessor :road_angle
  attr_accessor :has_woods
  attr_accessor :woods_type

  def inspect
    return "#<Hex: (#{object_id}) #{to_s}>"
  end

  def odd?
    return x % 2 == 1? true : false
  end

  def even?
    return !odd?
  end

  def neighbors
    n = []


    n << map[x][y-1] if y > 1
    n << map[x][y+1] if y < MAX_Y

    n << map[x-1][y] if x > 1
    n << map[x+1][y] if x < MAX_X

    if odd? and y > 1
      n << map[x-1][y-1] if x > 1
      n << map[x+1][y-1] if x < MAX_X
    end

    if even? and y < MAX_Y
      n << map[x-1][y+1] if x > 1
      n << map[x+1][y+1] if x < MAX_X
    end

    return n
  end

  def in_direction n
    if n == 0
      return map[x][y-1]
    elsif n == 3
      return map[x][y+1]
    elsif n == 1
      return nil if x >= MAX_X
      if odd?
        return nil if y <= 1
        return map[x+1][y-1]
      else
        return map[x+1][y]
      end
    elsif n == 2
      return nil if x >= MAX_X
      if odd?
        return map[x+1][y]
      else
        return map[x+1][y+1]
      end
    elsif n == 4
      return nil if x <= 1
      if odd?
        return map[x-1][y]
      else
        return map[x-1][y+1]
      end
    elsif n == 5
      return nil if x <= 1
      if odd?
        return map[x-1][y-1]
      else
        return map[x-1][y]
      end
    end
  end

  def direction_to(n)
    6.times do |d|
      if in_direction(d) == n
        return d
      end
    end
    return nil
  end

  def initialize map, x, y
    @map = map
    @x = x
    @y = y
    @level = 0
  end

  def name
    return "%02d%02d" % [x, y]
  end

  def to_s
    return name
  end

  def clear?
    return (!has_woods and !has_road)
  end

  def hilliness v=Set[]
    if v.include?(self)
      return 0
    end

    v.add(self)
    if level == 0
      return 1
    else
      return level + neighbors.map{|h|h.hilliness(v)}.sum
    end
  end

  def make_hill(target, rng)
    while (h = hilliness) < target
      #puts("Current hex: #{name}")
      #puts("Neighbors: #{neighbors.map(&:to_s)}")
      o = neighbors.select{|n| n.level < @level}

      n_levels = o.map(&:level)
      max_level = n_levels.max
      max_level = 0 if max_level.nil?

      n_within_1 = n_levels.count{|n| n >= @level - 1}

      self_weight = 10 * (n_within_1)
      self_weight += (MAX_LEVEL - @level) * 5

      max_neighbor = neighbors.map(&:level).max
      if (max_neighbor > @level)
        self_weight += 20
      end

      if level - max_level > 2
        self_weight = 0
      end
      #puts("Current level: #{level}")
      #puts("Current hilliness: #{h}")
      #puts("Self weight: #{self_weight}")
      #puts("Adjacent, lower hexes: #{o.map(&:name)}")

      if self_weight == 0 and o.empty?
        # puts "Somehow too high and also no lower neighbors"
        @level = @level + 1
      elsif rng.rand(100) < self_weight or o.empty?
        # puts("Choosing to raise self")
        @level = @level + 1
      else
        t = o.sample(random: rng)
        # puts("Choosing to raise #{t}")
        t.make_hill(target, rng)
      end
    end
  end

  def make_woods(rng)
    n_heavy = [0,0,0,1,1,2].sample(random:rng)
    n_light = [1,2,2,2,2,3,3,3].sample(random:rng)
    if n_heavy > 0 and n_light > 1
      n_light -= 1
    end

    if n_heavy > 0
      n_heavy -= 1
      has_woods = true
      woods_type = 2
    end

    n_heavy.times do 
      h = in_direction(rng.rand(6))
      if !h.nil? and h.clear?
        h.has_woods = true
        h.woods_type = 2
      end
    end

    n_light.times do
      h = in_direction(rng.rand(6))
      if !h.nil? and h.clear?
        h.has_woods = true
        h.woods_type = 1
      end
    end
  end
end

def simple_dump(map, filename)
  f = File.open(filename, "w")
  f.write('<?xml version="1.0" encoding="UTF-8"?>')
  f.write('<map xmlns="http://pqz.us/btmap">')
  f.write("\n")
  for x in 1..MAX_X
    for y in 1..MAX_Y
      h = map[x][y]
      f.write('<hex column="%d" row="%d"><level>%d</level>' % [h.x, h.y, h.level])
      if h.has_road
        if h.road_type < 0
          type = "left"
        elsif h.road_type > 0
          type = "right"
        else
          type = "straight"
        end
        f.write('<path orientation="%d">%s</path>' % [h.road_angle, type])
      end
      if h.has_woods
        if h.woods_type == 1
          type = "light"
        elsif h.woods_type == 2
          type = "heavy"
        end
        f.write("<woods>#{type}</woods>\n")
      end
      f.write("</hex>\n");
    end
  end
  f.write("</map>")
  f.close()
end

map = []
for x in 1..MAX_X
  map[x] = []
  for y in 1..MAX_Y
    map[x][y] = Hex.new(map, x, y)
  end
end

p map[2][2].name
p map[2][2].neighbors.map(&:name)

p map[5][6].name
p map[5][6].neighbors.map(&:name)

p map[3][1].neighbors.map(&:to_s)

h0202 = map[2][2]

arg = ARGV[0].to_i
if (arg == 0) 
  rng = Random.new()
else
  rng = Random.new(arg)
end

(rng.rand(5) + 15).times do 
  x = rng.rand(MAX_X) + 1
  y = rng.rand(MAX_Y) + 1

  hex = map[x][y]
  puts("Making hill at #{hex}")

  hex.make_hill(20 + rng.rand(40), rng)
end

def smooth(h, rng)
  steep_down = h.neighbors.filter{|n| n.level < (h.level - 1)}
  if steep_down.size > 3
    steep_down.each do |d|
      if rng.rand(3) == 0
        d.level = d.level + 1
        smooth(d, rng)
      end
    end
  end
end

def smooth_up(h, rng)
  tall_neighbors = h.neighbors.filter{|n| n.level > (h.level + 1)}
  if tall_neighbors.size > 1
    f = h.neighbors.map{|n| n.level - h.level}.filter(&:positive?).sum
    unless rng.rand(f) == 0
      h.level = h.level + 1
    end
  end
end

def pathfind(s, e, o)
  visited = Set.new
  dist = Hash.new

  dist[s] = 0
  prev = Hash.new

  while (!(c = get_next(dist, visited)).nil?) and !visited.include?(e)
    p = prev[c]
    if p.nil?
      orientation = o
    else
      orientation = c.direction_to(p)
    end

    n = Set.new
    n << c.in_direction((orientation + 2) % 6)
    n << c.in_direction((orientation + 3) % 6)
    n << c.in_direction((orientation + 4) % 6)

    n = n - visited
    n.delete nil 

    n.each do |x|
      if (x.level - c.level).abs > 1
        cost = 5000
      elsif (x.level - c.level).abs > 0
        cost = 100
      else
        cost = 50
      end

      if (n != c.in_direction((orientation + 3) % 6))
        cost += 20
      end

      if (x.has_woods)
        cost += 10
      end

      next if cost > 1000

      if dist[x].nil? 
        dist[x] = 0
      end
      dist[x] = dist[c] + cost
      prev[x] = c
    end
    visited << c
  end

  if dist[e].nil?
    return nil
  end

  path = []

  while !(c = prev[e]).nil?
    path << e
    e = c
  end

  path << s
  return path.reverse
end

def get_next(dist, visited)
  d = dist.filter{|k,v| !visited.include? k}.keys
  return nil if d.empty?

  n = d.first
  d.each do |x|
    if dist[x] < dist[n]
      n = x
    end
  end

  return n.nil? ? nil : n
end

(rng.rand(10) + 8).times do 
  x = rng.rand(MAX_X) + 1
  y = rng.rand(MAX_Y) + 1

  map[x][y].make_woods(rng)
end

map[1..MAX_X].each do |c|
  c[1..MAX_Y].each do |h|
    smooth(h, rng)
  end
end

map[1..MAX_X].each do |c|
  c[1..MAX_Y].each do |h|
    smooth_up(h, rng)
  end
end

s = map[1][9]
e = map[15][9]
path = pathfind(s, e, 5)
p path


unless path.nil?
  back = Hash.new
  foreward = Hash.new
  path.size.times do |i|
    if i == 0
      back[path[i]] = 5
    else
      back[path[i]] = path[i].direction_to(path[i-1])
    end

    if i == (path.size - 1)
      foreward[path[i]] = 2
    else
      foreward[path[i]] = path[i].direction_to(path[i+1])
    end
  end

  path.each do |h|
    h.has_road = true
    h.road_angle = (back[h] + 3) % 6

    a = foreward[h] - back[h]
    if a.abs == 3 
      h.road_type = 0
    elsif a == 2 or a == -4
      h.road_type = -1
    elsif a == 4 or a == -2
      h.road_type = 1
    else
      puts "PROBLEM"
      p h
      p "f:#{foreward[h]} b#{back[h]}"
      h.road_type = 0
    end
  end
end



simple_dump(map, "map.xml")

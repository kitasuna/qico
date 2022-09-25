# qico
Qico (KEY-ko in my brain, but pronounce it however you want!) is a basic event queue for Pico-8.

It is somewhat similar to the Observer pattern outlined in the fantastic [Game Programming Patterns](https://gameprogrammingpatterns.com/) (and elsewhere), but the semantics are a little different.

As a programming pattern, it allows us to decouple disparate logic that may be executed as the result of some event, without putting all that logic into the same place and making a giant mess of things.

# usage
Clone this repository and copy the `qico.lua` file to your project. You can paste the whole thing in, or use it as an include. I prefer to do the latter:

```
#include qico.lua
```

You would then initialize Qico by calling the `qico` function. You can assign it to whatever variable name you'd like. I used `q`:

```
q = qico()
```

Now we'll add some "topics" which are things that our "subscribers" will want to be notified about. As an example, let's assume we'll have two entities in our game: a player and a baddie. Both of these entities will want to react if they collide, but each entity's action will be different.

In any case, let's add a "collision" topic to Qico now using the `add_topics` function:

```
q.add_topics("collision")
```

You can add multiple topics by separating them with a `|` (pipe) character. For example, if we wanted to have a topic for collision and another for initializing a level, we'd write something like this:

```
q.add_topics("collision|init_level")
```

You don't have to include a `|` character after the last topic name.

## adding subscriptions
Now that we have our topics created, let's make some subscribers. I'll elide some of the boilerplate code here (you can check all of it in the [examples](./examples) directory in this repo), but let's assume we have a player variable and corresponding `draw` function defined as below:

```
player = {
  pos = {48,64}, -- (x, y)
  size = {8, 8}, -- (w, h)
  color = 12, -- light blue
}

player.draw = function()
  rectfill(player.pos[1], player.pos[2], player.pos[1] + 8, player.pos[2] + 8, player.color)
end
```

Similarly, our baddie will be defined like this:

```
baddie = {
  pos = {112, 64}, -- (x, y)
  size = {8, 8}, -- (w, h)
  color = 8, -- red 
}
baddie.draw = function()
  rectfill(baddie.pos[1], baddie.pos[2], baddie.pos[1] + 8, baddie.pos[2] + 8, baddie.color)
end
```

So, we've made them both a couple of squares. Let's make sure we can see our blue player and our red baddie:

![Player and baddie](https://github.com/kitasuna/qico/blob/a860cc816bcbdac75a5561ff7ea5ee760da6663c/gifs/example-init.gif?raw=true)

We can give each of these entities some functionality to run when a collision occurs. For the player, let's assume that the player "dies" and its position is reset:

```
player.handle_collision = function()
  player.pos = {48, 64}
end
```

And for the baddie, let's change its color to something random:

```
baddie.handle_collision = function()
  baddie.color = flr(rnd(15))
end
```

Note that I've named both of these functions `handle_collision`, but you can call them whatever you'd like.

Next, we need to register these functions as "subscriptions" for our collision topic. We'll do this using the `add_subs` function. The function takes the name of the topic, and a table containing all the functions that will be called when this event occurs:

```
q.add_subs("collision", {player.handle_collision, baddie.handle_collision})
```

There is also an `add_sub` function if you want to use fewer tokens and add only a single subscription for a given topic.

Next, we need to figure out the circumstances that will trigger the collision event. Assuming we have a `collides` function that will check that for us, our code would look like this:

```
function _update()

-- some other game loop stuff probably happens here

--- check for collision and add event if it happens
  if collides(player, baddie) then
    q.add_event("collision")
  end

end
```

I would normally put this kind of code in the `_update` or `_update60` function, or some function called by those functions, to ensure it would be called with each frame.

The `add_event` function added an event to the queue, and in a normal game, there would probably be several events added to the queue in a given frame. But that doesn't mean anything has happened yet! At some point, we'll have to process those events, using the `proc` function. A natural place to do that would be at the end of the `_update` function:

```
function _update()

-- some other game loop stuff probably happens here

--- check for collision and add event if it happens
  if collides(player, baddie) then
    q.add_event("collision")
  end

  q.proc()
end
```

When `proc` is called, it will loop through each event in the queue, and check if that event has any subscribers. If so, it will call the function that was passed in `add_subs`, and execute the corresponding code. In our case, that means both `player.handle_collision` and `baddie.handle_collision` will be called.

That's it for the setup! Let's see it in action:

![Collision example](https://github.com/kitasuna/qico/blob/a860cc816bcbdac75a5561ff7ea5ee760da6663c/gifs/example-collision.gif?raw=true)

Here, we can see the player's position being reset, as well as the baddie assuming a new, randomized color.

## payloads

Sometimes, we may want to pass some extra information to our subscribers when an event happens. Qico supports passing an argument to each handler function if it receives one in the call to `add_event`.

As an example, let's alter our example to change the player's name every time it dies. First let's add a `name` property to the player and give it a default value of "P1":

```
player = {
  pos = {48,64}, -- (x, y)
  size = {8, 8}, -- (w, h)
  color = 12, -- light blue
  name = "P1",
}
```

We'll also update the player's `draw` function to print the name above it, so we can see that it's working:
```
player.draw = function()
  print(player.name, player.pos[1], player.pos[2] - 8, player.color)
  rectfill(player.pos[1], player.pos[2], player.pos[1] + 8, player.pos[2] + 8, player.color)
end
```

And update the collision handler to accept an argument, which we'll call `new_name`. We'll use this value to update the player's `name` property:

```
player.handle_collision = function(new_name)
  player.name = new_name
  player.pos = {48, 64}
end
```

Finally, when we detect a collision, we'll pick randomly choose one of several (short) names to pass to the player:

```
if collides(player, baddie) then
  local names = {"bo", "ao", "ai", "jo"}
  local new_name = names[flr(rnd(#names) + 1)]
  q.add_event("collision", new_name)
end
```

Testing this, we can see that with each player death and respawn, the player name updates:

![Collision example](https://github.com/kitasuna/qico/blob/a860cc816bcbdac75a5561ff7ea5ee760da6663c/gifs/example-name-change.gif?raw=true)

You may have noticed that we didn't update the baddie's `handle_collision` method to accept the name argument. Technically, the argument is still passed to the baddie's handler function, but because we don't define any arguments in the function header itself, it's simply ignored.

# api
## add_event("topic_name"[, payload])
Adds an event to the queue, with an optional payload parameter

## add_topics("topic_name1|topic_name2|..")
Adds topics. Multiple topics should be separated by a `|` character

## add_sub("topic_name", fn)
Add a subscription to a given topic

## add_subs("topic_name", {fn1, fn2, ..})
Adds multiple subscriptions to a given topic

## proc
Processes all events in the queue

## q
A table containing queued events. Only modify this direction if you're feeling brave

## t
A table containing topics and their corresponding subscriptions. Only modify this directly if you're feeling brave

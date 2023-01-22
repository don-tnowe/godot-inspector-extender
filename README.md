# Inspector Extender

A plugin for Godot 4 to extend the Inspector using just comments above properties. Nodes, Resources, and even non-tool scripts supported!

It allows the user to do this:

![](./images/screen0.png)

...with just this.

![](./images/screen1.png)

Comments must be placed any number of lines before the property they must be applied to (*place anything in between, just not other properties*)

Supported commentributes:

## @@message(`message_func`), @@message_warning(`message_func`), @@message_error(`message_func`)

Call `message_func` that returns a message string to display a message. When the function returns and empty string, no message is displayed.

## @@buttons(`params`)

Displays a button group. The `params`, comma-separated, must contain expressions (*like `set_position(position + Vector2(9, 20))`*), preceded by a name (*inside quotation marks `" "`*) and optionally a color code (*like `#009900`*)

To display a red "Reset" button that calls `_reset`, write: `# @@buttons("Reset", #990000, _reset())`.

**Note:** Assignment `=` `+=` `*=` `-=` `/=` not supported, use setter functions instead.

**Note:** Translating nodes in viewport has unpredictable behaviour. Clues on fixes appreciated.

## @@dict_table(`params`)

Displays list of dictionaries as a table. The `params`, comma-separated, must be in format of `key : type`, where `key` is the dictionary's key and `type` is the name of its datatype.

To store a table of dictionaries each containing a number `a`, a 2d-vector `b` and a texture `c`, write `# @@dict_table( a : int, b : Vector2, c : Texture2D)`.

## @@resource_table(`properties`)

Displays list of resources as a table. Optionally, list `properties` to display.

## More commentributes coming soon.

#
Made by Don Tnowe in 2023.

[My Website](https://redbladegames.netlify.app)

[Itch](https://don-tnowe.itch.io)

[Twitter](https://twitter.com/don_tnowe)

Copying and Modification is allowed in accordance to the MIT license, full text is included.

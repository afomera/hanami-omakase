> [!WARNING]
> This project is not affiliated with the Hanami team, but a mere user of Hanami itself.  The name Hanami Omakase was chosen to indicate it works with Hanami specifically and not other frameworks. DO NOT REPORT ISSUES FROM HERE TO HANAMI.

# hanami-omakase [![Gem Version](https://badge.fury.io/rb/hanami-omakase.svg)][rubygem] [![CI Status](https://github.com/afomera/hanami-omakase/workflows/CI/badge.svg)][actions]

Hanami Omakase is a collection of defaults picked for you, to get productive with Hanami fast, along with some extensions and utilities to make you happy.

Inspired by mega-frameworks in the Ruby space where defaults out of the box allow you to get productive, but with the ability to retain and fall back to the modular aspect of Hanami.

## License

See `LICENSE` file.

## Installation

```sh
bundle add hanami-omakase
```

In `config/app.rb`:

```rb
require "hamami"
require "hamami/omakase"
```

That's all for now, you'll have access to the Core Extensions listed below throughout your Hanami application.

## Features:

### Hanami View

#### url_for / path_for helper

In standard Hanami you can access route paths and urls with `routes.path(:named_route, id: ...)` or `routes.url`. Hanami Omakase adds `url_for(:named_route, id: ...)` and `path_for` methods to help clean it up slightly.

```erb
<div>
  <%= link_to "New", path_for(:new_article) %> -
  <%= link_to "Show", path_for(:article, id: article[:id]) %> -
  <%= link_to "Edit", path_for(:edit_article, id: article[:id]) %>
</div>
```

### Hanami Action

We patch Hanami::Action in your Hanami applications to give a Developer Experience that will feel familiar for users of certian train themed frameworks in Ruby.

#### Important Note on format support

If you wish to use specific formats in the respond_to block, your config and `Hanami::Action` base action will likely need to define them to keep things clean.

For example in `app/action.rb` add, then all children classes of AppName::Action will opt-in for the formats.

```rb
    format :html, :json, :md, :xml
```

For markdown support you'll need to add to the `config/app.rb` class

```rb
config.actions.formats.add(:md, "text/markdown")
```

You'll also need to define route formats for the endpoint to opt into it.

```rb
get "/books(.:format)", to: "books.index"
```

for example to allow any format to be passed through to the Action.

#### respond_with

Allows creating a `respond_with` block that is provided a format argument with `format.html` or `json`, `md`, or `xml` that can return a response body / render a view for the response. Currently only `html`, `json`, `md` and `xml` are supported, and cannot be extended. If you've got a format you'd love support for, please PR it and we can discuss.

Hanami Omakase automatically handles setting the format / content type for you per the format specified in the block, as well as passing it through the `render` method on the `response`.

**Note:** If you use `json` or `xml` formats, `layout` passed to `response.render` is automatically set to `nil`, but if you need to specify a layout you can pass the layout name `layout: "app"` to the `render(view, layout: "app")` call.

If you need to return a specific response body for a format you have access to the response object just like in regular Hanami.

`render` inside of a `format` block is a short-hand syntax for `response.render` so all regular Hanami `response.render` call options will work as before.

```rb
module Playground
  module Actions
    module Articles
      class Index < Playground::Action
        def handle(request, response)
          page_param = (request.params[:page] || 1).to_i

          respond_with do |format|
            format.html { render(view, per_page: 10, page: page_param) }
            format.json { render(view, per_page: 100, page: page_param) }
            format.md { response.body = "# Hello world" }
          end
        end
      end
    end
  end
end
```

### Core Extensions

#### Integer

- Adds support for `seconds`, `minutes`, `hours`, `days`, `weeks` and `years` methods on Integers to return a given number multiplied by the respective values to return the integer in seconds.

```ruby
1.second #=> 1
5.seconds #=> 5
1.minute #=> 60
1.hours #=> 3600
1.day #=> 86400
1.week #=> 604800
365.days #=> 31536000
1.year #=> 31536000
```

There are plural and singular methods for those mentioned above.

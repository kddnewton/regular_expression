# DEPRECATED

Being replaced by [kddnewton/exreg](https://github.com/kddnewton/exreg).

# RegularExpression

[![Build Status](https://github.com/kddnewton/regular_expression/workflows/Main/badge.svg)](https://github.com/kddnewton/regular_expression/actions)
[![Gem Version](https://img.shields.io/gem/v/regular_expression.svg)](https://rubygems.org/gems/regular_expression)

A regular expression engine written in Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "regular_expression"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install regular_expression

### Dependencies

#### Cranelift

One of the backends that the regular expression compiler can use is cranelift, which is a rust project with Ruby bindings handled by the `cranelift_ruby` gem. In order to use the compiler, you'll need to have `cargo` installed so that it can compile the rust native extension. On a Mac or Linux you can `curl https://sh.rustup.rs -sSf | sh`. For other platforms, searching _install cargo_ can tell you how. Additionally, you'll need your Ruby to have been compiled with the `--enable-shared` option.

#### Capstone

To call `#disasm` on the generated machine code, you'll need Capstone installed. On a Mac you can `brew install capstone`, or on Ubuntu you can `sudo apt-get install libcapstone-dev`. For other platforms, searching _install capstone_ can tell you how.

#### Graphviz

To call `#to_dot` on the syntax tree or the state machines, or run the tests, you'll need Graphviz installed. On a Mac you can `brew install graphviz`, or on Ubuntu you can `sudo apt-get install graphviz`. For other platforms, searching _install graphviz_ can tell you how.

## Usage

To create a regular expression pattern, use:

```ruby
pattern = RegularExpression::Pattern.new("ab?c")
```

Patterns can be queried for whether or not they match a test string, as in:

```ruby
pattern.match?("abc") # => true
pattern.match?("ac") # => true
pattern.match?("ab") # => false
```

## Development

After [installing the dependencies](#dependencies) checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Status

At the moment we support most basic features, but there is a lot of ground left to cover. Some of them are written out in issues, while others are just documented here. Here is the current list as it stands:

| Syntax                                                                                                             | Status | Issue                                                            |
| ------------------------------------------------------------------------------------------------------------------ | ------ | ---------------------------------------------------------------- |
| [Character classes](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Character+Classes)              | 🛠      | [#6](https://github.com/kddnewton/regular_expression/issues/6)   |
| [Repetition](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Repetition)                            | ✅     |                                                                  |
| [Non-greedy repetition](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Repetition)                 | ❌     |                                                                  |
| [Capturing](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Capturing)                              | 🛠      | [#3](https://github.com/kddnewton/regular_expression/issues/3)   |
| Named captures                                                                                                     | ✅     | [#84](https://github.com/kddnewton/regular_expression/issues/84) |
| [Grouping](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Grouping)                                | ✅     |                                                                  |
| [Atomic grouping](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Atomic+Grouping)                  | ❌     |                                                                  |
| [Subexpression calls](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Subexpression+Calls)          | ❌     |                                                                  |
| [Alternation](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Alternation)                          | ✅     |                                                                  |
| [Character properties](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Character+Properties)        | 🛠      | [#8](https://github.com/kddnewton/regular_expression/issues/8)   |
| [Anchors](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Anchors)                                  | 🛠      | [#9](https://github.com/kddnewton/regular_expression/issues/9)   |
| [Assertions](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Anchors)                               | 🛠      | [#10](https://github.com/kddnewton/regular_expression/issues/10) |
| [Case-insensitive mode](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Options)                    | 🛠      | [#4](https://github.com/kddnewton/regular_expression/issues/4)   |
| [Multi-line mode](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Options)                          | ❌     | [#5](https://github.com/kddnewton/regular_expression/issues/5)   |
| [Free-spacing mode](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Free-Spacing+Mode+and+Comments) | ✅     | [#11](https://github.com/kddnewton/regular_expression/issues/11) |
| [Encoding support](https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Encoding)                        | ❌     | [#12](https://github.com/kddnewton/regular_expression/issues/12) |
| Backreferences                                                                                                     | ❌     |                                                                  |

## Benchmarking

To benchmark the current performance on your current version of Ruby, run:

    $ bundle exec rake benchmark

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kddnewton/regular_expression. For information about how to contribute to the development of this gem, see the [CONTRIBUTING.md](CONTRIBUTING.md) document.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

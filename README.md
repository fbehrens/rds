RDS - Redis backed up Ruby Objects 
==================================

**Git**:          [http://github.com/fbehrens/rds](http://github.com/fbehrens/rds)   
**Author**:       Frank Behrens  
**Contributors**: See Contributors section below    
**Copyright**:    2011    
**License**:      MIT License    
**Latest Version**: 0.7.1 (codename "Heroes")    
**Release Date**: May 18th 2011    

Synopsis
--------

rds is a documentation generation tool for the Ruby programming language
It enables the user to generate consistent, usable documentation that can be
exported to a number of formats very easily, and also supports extending for
custom Ruby constructs such as custom class level definitions. Below is a
summary of some of rds's notable features.


Feature List
------------
                                                                              
**1. Attribute Accessors**: show example 

**2. Associations**: see following code example 

     class Person
       include Rds::Model
     end
                                                                     
With the above @param tag, we learn that the contents parameter can either be
a String or any object that responds to the 'read' method, which is more 
powerful than the textual description, which says it should be an IO object. 
This also informs the developer that they should expect to receive a String 
object returned by the method, and although this may be obvious for a 
'reverse' method, it becomes very useful when the method name may not be as 
descriptive. 
                                                                              
**3. Indexes and Scopes**: rds is designed to be 
extended and customized by plugins. Take for instance the scenario where you 
need to document the following code: 
   
    class List
      # Sets the publisher name for the list.
      cattr_accessor :publisher
    end
                                                                        
This custom declaration provides dynamically generated code that is hard for a
documentation tool to properly document without help from the developer. To 
ease the pains of manually documenting the procedure, rds can be extended by 
the developer to handle the `cattr_accessor` construct and automatically create
an attribute on the class with the associated documentation. This makes 
documenting external API's, especially dynamic ones, a lot more consistent for
consumption by the users. 


Installing
----------

To install rds, use the following command:

    $ gem install yard
    
(Add `sudo` if you're installing under a POSIX system as root)
    
Alternatively, if you've checked the source out directly, you can call 
`rake install` from the root project directory.

**Important Note for Debian/Ubuntu users:** there's a possible chance your Ruby
install lacks RDoc, which is occasionally used by rds to convert markup to HTML. 
If running `which rdoc` turns up empty, install RDoc by issuing:

    $ sudo apt-get install rdoc
                                                                              

Usage
-----

There are a couple of ways to use rds. The first is via command-line, and the
second is the Rake task. 

**1. yard Command-line Tool**

rds comes packaged with a executable named `yard` which can control the many
functions of rds, including generating documentation, graphs running the
rds server, and so on. To view a list of available rds commands, type:

    $ yard --help
    
Plugins can also add commands to the `yard` executable to provide extra
functionality.

### Subchapter

<span class="note">The `yardoc` executable is a shortcut for `yard doc`.</span>

The most common command you will probably use is `yard doc`, or `yardoc`. You 
paths and globs from the commandline via:

    $ yardoc 'lib/**/*.rb' 'app/**/*.rb' ...etc...
    
The `yardoc` tool also supports a `--query` argument to only include objects
the same result:

    --query 'has_tag?(:api) && tag(:api).text == "public"'

For more information about the query syntax, see the {rds::Verifier} class.

**2. Rake Task**

The second most obvious is to generate docs via a Rake task. You can do this by 
adding the following to your `Rakefile`:

    rds::Rake::YardocTask.new do |t|
      t.files   = ['lib/**/*.rb', OTHER_PATHS]   # optional
      t.options = ['--any', '--extra', '--opts'] # optional
    end

both the `files` and `options` settings are optional. `files` will default to
OPTS environment variable:

### Live Reloading

If you want to serve documentation on a project while you document it so that
change any documentation in the source and refresh to see the new contents.

### Serving Gems

To serve documentation for all installed gems, call:

    $ yard server --gems
    
This will also automatically build documentation for any gems that have not
been previously scanned. Note that in this case there will be a slight delay
between the first request of a newly parsed gem.


**5. `yard graph` Graphviz Generator**

You can use `yard-graph` to generate dot graphs of your code. This, of course,
requires [Graphviz](http://www.graphviz.org) and the `dot` binary. By default
ore options can be seen by typing `yard-graph --help`, but here is an example:

    $ yard graph --protected --full --dependencies


Changelog
---------

- **June.16.11**: 0.7.1 release
    - add README.md

Contributors
------------

Special thanks to the following people for submitting patches:

* Frank Behrens

Copyright
---------

rds &copy; 2011 by [Frank Behrens](mailto:fbehrens@gmail.com). rds is 
licensed under the MIT license except for some files which come from the
RDoc/Ruby distributions. Please see the {file:LICENSE} and {file:LEGAL} 
documents for more information.

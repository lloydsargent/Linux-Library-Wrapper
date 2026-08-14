# How to wrap a library from scratch.

I’m assuming you’ve already installed Swift, but in case you haven’t, here’s how to do it:
```
curl -O https://download.swift.org/swiftly/darwin/swiftly.pkg && \
installer -pkg swiftly.pkg -target CurrentUserHomeDirectory && \
~/.swiftly/bin/swiftly init --quiet-shell-followup && \
. "${SWIFTLY_HOME_DIR:-$HOME/.swiftly}/env.sh" && \
hash -r
```
Cool. So now Swift is installed. Let’s generate a simple program called MyCLI. Move to a directory that you want to make your project in. Then use the following line:
```
swift package init --name MyCLI --type executable
```
It will spit out these lines:
```
Creating executable package: MyCLI
Creating Package.swift
Creating .gitignore
Creating Sources
Creating Sources/MyCLI/MyCLI.swift
Creating Tests/
Creating Tests/MyCLITests/
Creating Tests/MyCLITests/MyCLITests.swift
```

If you list your directory, you should see this:
```
Package.swift  Sources  Tests
```
Now run it. 
```
swift run MyCLI
```
This will give you:
```
Building for debugging...
[8/8] Linking MyCLI
Build of product 'MyCLI' complete! (1.51s)
Hello, world!
```

## At this point you will ask, “Why are we doing something so basic?”
It’s to get a point of reference. We need to start somewhere. This, hopefully, gets us all on the same page. 

## Now the fun part, getting SDL3 working

Time to jump in the deep end of the pool. SDL3 doesn’t have an apt-get package. I want to use SDL3. I can either cry or get with the program. So I get with the program.  

1. Create a directory and do a git clone of the latest release of SDL3 — if I’ve lost you, then ignore the rest of this because we’re getting deeper than that.
2. Build SDL3 like so:
```
cmake -S . -B build -DSDL_STATIC=ON -DSDL_SHARED=ON
```
```
cmake --build build
```
```
sudo cmake --install build --prefix /usr/local
```

If you look in the `/usr/local/lib` you should see something like this:
```
cmake    libSDL3.so    libSDL3.so.0.4.14  python3.12 libSDL3.a   libSDL3.so.0  libSDL3_test.a  pkgconfig
```

What is important here is the `pkgconfig` because it makes all of this work. 

## Cool, everything is as you say it should

Cool, cool.  Lets move on to Package.swift

Going back to your Swift directory, we’re going to mess with Package.swift. It took me days to figure this out because everyone wanted to make things complicated. Because software geeks. I’m going to simplify it for y’all because I’m simple.

Package.swift looks like this. Just accept it because you’re not going to get around not using it.

```
import PackageDescription

let package = Package(
    name: "MyCLI",
    targets: [
        .executableTarget(
            name: "MyCLI"
        ),
        .testTarget(
            name: "MyCLITests",
            dependencies: ["MyCLI"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
```
Okay, what’s important here is executable because that is our executable (duh). Honestly, what you see if pretty much reality. Okay, cool. Now, let’s modify things.

```
// swift-tools-version: 6.3

// ^^^ that line MUST exist or you will get an error. Don’t remove it thinking it’s
//     just a comment. Or remove it and see what happens. Trust me.

import PackageDescription

let package = Package(
    name: "MyCLI",
    dependencies: [ ],
    targets: [
        .systemLibrary(
            name: "CSDL3",
            // These are the names in /usr/local/lib/pkgConfig
            // The pkgConfig files refer to the REAL libraries
            pkgConfig: "sdl3",
            providers: [ ]
        ),
        .executableTarget(
            name: "MyCLI", 
            dependencies: [ "CSDL3"],
         ),
        .testTarget(
            name: "MyCLITests",
            dependencies: ["MyCLI"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
```
Here is the secret sauce as it were, line by line. First, we tell it there is a .system library (don’t ask, I’m not a guru, I just wanted to make it work).
```
.systemLibrary(           // all I know is that this works
    name: "CSDL3”,        // what we are call all of it
    pkgConfig: "sdl3”,    // packages we are using that are in /usr/local/lib/pkgconfig
    providers: [ ]        // where it comes from (does nothing today)
),
```
This other bit lets us know that the stuff defined in `.systemLibrary` needs to be linked into our executable.
```
.executableTarget(
    name: "MyCLI", 
    dependencies: [ "CSDL3”],    // <== This part matches the name from above.
 ),
```
Okay, there is the link: we find the package config file and that tells us the file we link into the program. It’s a bit round-about but that gives us our linkage. 

However, this only helps with the linker. It doesn’t really help us when compiling. For that, we need another bit of magic. At this point, you should all go “OHHHHH!” Because it was the part that I was missing before I figured it out. And what is weird is that it can look like it compiles and links but crashes when you run.

## The magic for the compile

At this point you have the following (MyCLIDirectory is whatever the name of your directory is that you built under—it really isn’t important)
```
MyCLIDirectory/
├── Package.swift
├── Sources/
│   └──MyCLI/
│      └── MyCLI.swift
└──Tests/
    └── ContentView.swift
```
But that isn’t enough because the compiler has no clue about SDL3. Or the headers. So if you attempt to do all the things needed to display a window you will get a lot of sad. Mostly it complaining about “I don’t know what you are talking about, boss!” so that’s not good. 

What you need is another directory under Sources that we’re going to name CSDL3. Can it be another name? Probably, I don’t know, I haven’t tried. I’m trying to get a project running and I just want to get it running. If it works for you, cool. 

So the directory structure we want is this:
```
MyCLIDirectory/
├── Package.swift
├── Sources/
│   ├──CSDL3/
│   │  └── module.modulemap
│   └──MyCLI/
│      └── MyCLI.swift
└──Tests/
    └── ContentView.swift
```
So here we added a directory under Sources named `CSDL3` and it has a file named `module.modulemap`. That module.modulemap is what makes the Swift compiler happy (it also autogens a file for headers and stuff and is actually pretty cool—like I was tots blown away). So, put this in the file named module.modulemap
```
module CSDL3 [system] {
    header "/usr/local/include/SDL3/SDL.h"
    export *
}
```
Okay, you’re probably getting the idea what is happening… We just told is where to find our header files. And this will make Swift so so happy!

Now modify MyCLI.swift so it looks like this:

```
import CSDL3

@main
struct MyCLI {
    static func main() {
        var deviceRenderer: OpaquePointer? = nil
        var deviceWindow: OpaquePointer? = nil

        SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_VIDEO)

        SDL_CreateWindowAndRenderer("MyName", 400, 300, SDL_WINDOW_MAXIMIZED, &deviceWindow, &deviceRenderer)

        SDL_SetRenderDrawBlendMode(deviceRenderer, SDL_BLENDMODE_BLEND)
        SDL_SetRenderTarget(deviceRenderer, nil)
        SDL_SetRenderDrawColorFloat(deviceRenderer!, 1.0, 1.0, 1.0, 1.0)
        SDL_RenderClear(deviceRenderer)
        SDL_RenderPresent(deviceRenderer)
        
        var quit = false
        while(quit == false) {
            var event: SDL_Event = SDL_Event()

            while (SDL_WaitEventTimeout(&event, 0) != false) {
                if event.type == 0x100 {
                    quit = true
                    break
                }
            }
            SDL_Delay(1)
        }
    }
}

let SDL_WINDOW_MAXIMIZED          : UInt64 = 0x0000000000000080    //**< window is maximized */
```

This should compile and you should get a white window. If you click the close button, it should close. Cool! 

## Why do we have to declare SDL_WINDOW_MAXIMIZED?

Yeah, here’s the thing. The internal Swift preprocessor is very smart. But it does not follow Marcos around. A lot of SDL3 has things like:
```
#define FOOBAR  0x10000  // this is cool and works right
```
So we don’t have to redefine the wheel. But there are things like
```
#define BARFOO  INT64(0x110010)   // Using macros? That is so uncool man
```
And Swift is wise not to follow macros. People do some very weird stuff with macros. So that’s why we had to declare SDL_WINDOW_MAXIMIZED.

## So what did we learn?

We learned how to wrap SDL3 in a package definition. You can wrap SDL_ttf and others do this very thing. Can you break it out? Probably, I just don’t know how to do it. Can you make a library? Probably, I just don’t know how to do it.

If you know how to make libraries and stuff, please share your wisdom with me and others. That would we awesome and cool!

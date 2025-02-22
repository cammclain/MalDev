In case you didn’t already realize what is going on here, we are essentially aiming to create my own private maldev academy experience!

The reason I am wanting to approach learning malware development through this customized and personalized method where I am having LLMs generate the lessons is simply because I cannot afford to pay for lifetime access to maldev academy. 


On top of this, maldev academy is highly opinionated. For example:

- Almost all the modules are in C & C++ (languages I don’t know and don’t really intend to learn if I can avoid it, since I use other languages already)
- It uses the Havoc Framework as it’s C2 framework 

So while it is worth noting I think the Havoc Framework is an amazing framework. it is well designed and generally extremely impressive piece of tooling, I am much more interested in designing my own C2 framework as well as my own implant from the ground up. 

Do not get me wrong I will be taking heavy inspiration from Havoc, however we are only aiming to emulate specific parts of it.

Another C2 I am fond of is Empire/Starkiller by BC Security. 
This C2 (in terms of the server itself) is very similar to what I am aiming to create for my private maldev C2, as it is written in python and is highly modular 

One difference in what I am looking to create and Starkiller is that I intend to use Litestar instead of Flask for the HTTP listener 

Also I’m pretty much only looking to develop HTTP(S) based C2 listeners, however I would like to use advanced technology and functionality that makes it so that the implant does not just communicate directly with the C2

For example:
- using oblivious HTTP proxies with cloudflare workers 
- malleable C2 profiles to make traffic appear different to an observer 



I am looking to create my own framework from the ground up that will serve as my personal alternative to Havoc while I dive deeper into this malware development process 

We will design the server side of the framework using Litestar + Advanced alchemy which is a modern extension of sqlalchemy 


My idea is to make a dashboard using HTMX and Litestar’s HTMX integration 



For the implant I want to develop a Rust based dropper which delivers an encrypted Zig based payload to the target 

The idea is that the Rust binary as the outer shell should make the binary appear more normal, allowing it the opportunity to deliver the zig payload and begin running it

I also like the idea of including Nim based shared object files to extend the Zig payload 

These shared objects can include optional functionally that can be included or excluded from individual builds, making the output unique across different engagements 

One of the most important features I want to include within this implant is the ability to pivot within the environment 
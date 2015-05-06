twitterpin
==========

The application performs a visual representation of the twitter stream. It starts a live connection on the twitter endpoint reading json chunks of the stream. After processing them it displays pins on a map correspoding to their location. The map is cleaned for tweets older than 10 seconds using a timer.

Every tweet is stored inside a CoreData store (which is not saved on disk). The app is not blocked while gathering tweets and updating them makes use of multithreading.

The app was programmed as an exercise. The code is also available on github.
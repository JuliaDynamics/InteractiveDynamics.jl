# Use this simple script to record an interaction happening on `figure`

framerate = 10
total_time = 30 # in seconds
framen = framerate*total_time

record(figure, "name.mp4"; framerate = framerate) do io
    for i = 1:framen
        sleep(1/framerate)
        recordframe!(io)
    end
end

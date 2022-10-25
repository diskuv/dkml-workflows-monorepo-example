{
    # trim leading and trailing space
    sub(/^ */, "");
    sub(/ *$/, "");

    print "export PATH='" $0 "'";
}
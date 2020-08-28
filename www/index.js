
// hide element
Shiny.addCustomMessageHandler('hide_loading', function(value) {
    document.getElementById(value).classList.add("visually-hidden");
});

// hide element
Shiny.addCustomMessageHandler('show_loading', function(value) {
    document.getElementById(value).classList.remove("visually-hidden");
});
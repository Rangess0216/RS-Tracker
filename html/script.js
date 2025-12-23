$(function() {
    window.addEventListener('message', function(event) {
        if (event.data.type === "open") {
            $("#app").css("display", "flex").hide().fadeIn(200);
        }
    });

    $("#accept-btn").click(function() {
        $.post('https://rs-tracker/startMission', JSON.stringify({}));
        $("#app").fadeOut(200);
    });

    $("#close-btn").click(function() {
        $.post('https://rs-tracker/closeUI', JSON.stringify({}));
        $("#app").fadeOut(200);
    });

    document.onkeyup = function(data) {
        if (data.which == 27) {
            $.post('https://rs-tracker/closeUI', JSON.stringify({}));
            $("#app").fadeOut(200);
        }
    };
});

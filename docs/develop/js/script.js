$(document).ready(function(){
    $('body').on("click","a[target!='_blank']", function(event) {
        event.preventDefault();
        var id  = $(this).attr('href');
        $("#wrapper").removeClass("toggled");
        if (id && id[0] === '#' && $(id)) {
            var top = $(id).offset().top - $('#top-menu:visible').height();
            $('body,html').animate({
                scrollTop: top
            }, {
                duration: 750,
                complete: function () {
                    var y = window.scrollY;
                    window.location = id;
                    window.scrollTo(window.scrollX, y);
                }
            });
        }
    });

    var lastId,
        menu = $('.sidebar-nav'),
        menuItems = menu.find("a"),
        scrollItems = menuItems.map(function(){
            var item = $($(this).attr("href"));
            if (item.length) { return item; }
        });

    $(window).scroll(function(){
        var fromTop = $(this).scrollTop();
        var cur = scrollItems.map(function(){
            if ($(this).offset().top - 40 < fromTop)
                return this;
        });
        cur = cur[cur.length-1];
        var id = cur && cur.length ? cur[0].id : "";

        if (lastId !== id) {
            lastId = id;
            menuItems
                .parent().removeClass("active")
                .end().filter("[href='#"+id+"']").parent().addClass("active");
        }
    });

    $("#top-menu .lines-button").click(function () {
        $("#wrapper").toggleClass("toggled");
    });

    $('.sidebar-language > a').click(function (e) {
        e.preventDefault();
        localStorage['lang'] = e.target.dataset.lang;
        location.reload();
    });

    $('.wrapper-background').click(function(e) {
        e.preventDefault();
        $("#wrapper").removeClass("toggled");
    });

    $('#subscribe_form').submit(function (event) {
        event.preventDefault();
        $('#subscribe_status').html('');
        $('#subscribe_captcha').html('');;
        document.getElementById('subscribe_btn').setAttribute('disabled', 'disabled');
        document.getElementById('subscribe_form_lang').value = window.lang;

        $.ajax({
            type: 'POST',
            url: 'https://api.prover.io/subscribe/request.php',
            dataType: "json",
            data: $(event.target).serialize(),
            cache: false,
            success: function (obj) {
                console.log(obj);
                response(obj);
            },
            error: function (obj) {
                console.log(obj.responseText);
            },
            complete: function () {
                document.getElementById('subscribe_btn').removeAttribute('disabled');
            }
        });
    });

    function response(obj) {
        if (typeof obj.result === "undefined") {
            return;
        }
        var st = $('#subscribe_status');
        var ct = $('#subscribe_captcha');
        switch (obj.result) {
            case 0:
                st.html("Ожидайте письма для завершения подписки");
                break;
            case 1:
                st.html("Вы должны ввести код с картинки");
                ct.html("");
                ct.append("<input type='hidden' name='verify_id' value='" + obj.verify_id + "'/> ");
                ct.append("<input type='text' name='code'/>&nbsp;");
                ct.append("<img src='data:image/png;base64," + obj.png_base64 + "'/><br><br>");
                break;
            case 2:
                st.html("Вы не заполнили нужные поля");
                break;
            case 3:
                st.html("Некорректный почтовый адрес");
                break;
            case 4:
                st.html("Вы уже подписаны");
                break;
            case 5:
                st.html("Невозможно проверить текст с картинки, прошло слишком много времени");
                break;
            case 6:
                st.html("Вы неверно ввели код с картинки");
                break;
            case 7:
                st.html("Повторную отправку на этот же адрес можно сделать через 5 минут");
                break;
            case 8:
                st.html("Ошибка на сервере");
                break;
        }
    }
});
'use strict';

import en_translate from './js/en_translation';
import ru_translate from './js/ru_translation';

let lang = navigator.languages && navigator.languages[0] ||
    navigator.language ||
    navigator.userLanguage;

if (localStorage.lang) {
    lang = localStorage.lang;
}

let translate = {};
translate['en'] = en_translate;
translate['ru'] = ru_translate;

function tr(code) {
    var trArray = translate['en'];
    if (lang === 'ru') {
        trArray = translate['ru'];
    }
    var translatedStr = code;
    if (trArray[code]) {
        translatedStr = trArray[code];
    } else {
        console.trace('No translate for ', lang, code);
    }
    document.write(translatedStr);
}

module.exports = {tr: tr, lang: lang};
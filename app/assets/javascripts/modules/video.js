import $ from 'jquery';
import 'remodal';

// (function() {
//   let player;
//
//   let ready = function() {
//     var tag = document.createElement('script');
//     tag.src = "https://www.youtube.com/iframe_api";
//     var lastScriptTag = $('script')[$('script').length - 1];
//     $(tag).insertAfter(lastScriptTag);
//   }
//
//   $(document).ready(ready)
// }).call(this);
//
// function onYouTubePlayerAPIReady() {
//   debugger
//   player = new YT.Player('getting-started', {
//     events: {
//       'onReady': onPlayerReady
//     }
//   });
// }
//
// function onPlayerReady(event) {
//   $(document).on('opened', '.video', function () {
//     player.playVideo();
//   });
//
//   $(document).on('closed', '.video', function (e) {
//     player.stopVideo();
//   });
// }

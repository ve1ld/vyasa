javascript:(function() {
    const timestamps = [];
    const durations = []
    const overlay = createOverlay();
    document.body.appendChild(overlay);

    document.addEventListener('keydown', handleKeyPress);

    function createOverlay() {
        const overlay = document.createElement('div');
        overlay.style.position = 'fixed';
        overlay.style.top = '50px';
        overlay.style.right = '0';
        overlay.style.backgroundColor = 'rgba(255,255,255,0.33)';
        overlay.style.color = 'white';
        overlay.style.padding = '10px';
        overlay.style.zIndex = '1000';
        return overlay;
    }

    function handleKeyPress(event) {
        if (event.key === '=') {
            captureTimestamp();
        } else if (event.key === 'Backspace') {
            removeNearestTimestamp();
        } else if (event.key === '+') {
            endTimestamp();
        }
    }

    function captureTimestamp() {
        const currentTime = getCurrentTime();
        if (currentTime !== null) {
            len = timestamps.length;
            timestamps.push(currentTime);
            if ((len > 0) && (durations[len -1] == null)) {
                // set prev duration
                durations[len -1] = currentTime - timestamps[len -1]
            }
            updateOverlay();
        }
    }

    function endTimestamp() {
        const currentTime = getCurrentTime();
        console.log(currentTime)
        if (currentTime !== null) {
            // find closest on the left time is >
            const closestIndex = findClosestLeftTimestampIndex(currentTime);
            durations[closestIndex] =  currentTime - timestamps[closestIndex];
            updateOverlay();
        }
    }

    function removeNearestTimestamp() {
        const currentTime = getCurrentTime();
        if (currentTime !== null) {
            const closestIndex = findClosestTimestampIndex(currentTime);
            prevTime = timestamps[closestIndex]
            timestamps.splice(closestIndex, 1);
            durations.splice(closestIndex)
            if ( closestIndex > 0 && prevTime == (timestamps[closestIndex -1] + durations[closestIndex -1])){
                durations.splice(closestIndex -1)}
            console.log(durations)

            updateOverlay();
        }
    }

    function getCurrentTime() {
        const player = document.getElementById('movie_player');
        return player ? player.getCurrentTime()*1000 : null;
    }

    function findClosestTimestampIndex(currentTime) {
        return timestamps.reduce((prev, curr, index, array) => {
            return (Math.abs(curr - currentTime) < Math.abs(array[prev] - currentTime) ? index : prev);
        }, 0);
    }

    // diff of curr < diff of prev and curr < currentTime
    function findClosestLeftTimestampIndex(currentTime) {
        return timestamps.reduce((prev, curr, index, array) => {
            return ((Math.abs(curr - currentTime) <= Math.abs(array[prev] - currentTime)) && (curr <= currentTime) ? index : prev);
        }, 0);
    }

    function updateOverlay() {
        overlay.innerHTML = '';
        timestamps.forEach((time, index) => {
            const link = createTimestampLink(time, index);
            overlay.appendChild(link);
            overlay.appendChild(document.createElement('br'));
        });

        const copyButton = createCopyButton();
        overlay.appendChild(copyButton);
    }

    function createTimestampLink(time, index) {
        const link = document.createElement('a');
        link.href = '#';
        link.textContent = `Event ${index + 1}: ${formatTime(time)} - ${formatTime(time + durations[index])} `;
        link.onclick = () => {
            const player = document.getElementById('movie_player');
            if (player) player.seekTo(time/1000);
            return false;
        };
        return link;
    }

    function createCopyButton() {
        const copyButton = document.createElement('button');
        copyButton.textContent = 'Copy Events';
        copyButton.onclick = () => {
            const jsonTimestamps = JSON.stringify(timestamps);
            copyToClipboard(jsonTimestamps);
        };
        return copyButton;
    }

    function formatTime(ms) {
        const minutes = Math.floor(ms / 60000);
        const remainingSeconds = ms % 60000;
        console.log(remainingSeconds)
        return `${minutes}:${remainingSeconds < 10000 ? '0' : ''}${String(remainingSeconds).substring(0,4) }`;
    }

    function copyToClipboard(text) {
        if (navigator.clipboard && window.isSecureContext) {
            return navigator.clipboard.writeText(text);
        } else {
            const textarea = document.createElement("textarea");
            textarea.value = text;
            textarea.style.position = "fixed";
            textarea.style.left = "-999999px";
            textarea.style.top = "-999999px";
            document.body.appendChild(textarea);
            textarea.focus();
            textarea.select();
            return new Promise((resolve, reject) => {
                document.execCommand("copy") ? resolve() : reject();
                textarea.remove();
            });
        }
    }
})();

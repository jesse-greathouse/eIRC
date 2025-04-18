import { ref } from 'vue';

export function useWebSocket(
    url: string,
    onMessage: (line: string) => void
) {
    const socket = ref<WebSocket | null>(null);

    function connect() {
        socket.value = new WebSocket(url);

        socket.value.onopen = () => {
            console.log('WebSocket connected');
        };

        socket.value.onmessage = (event) => {
            onMessage(event.data); // raw text, not JSON
        };

        socket.value.onclose = () => {
            console.log('WebSocket disconnected');
        };

        socket.value.onerror = (err) => {
            console.error('WebSocket error:', err);
        };
    }

    function send(line: string) {
        if (socket.value?.readyState === WebSocket.OPEN) {
            socket.value.send(line);
        }
    }

    function disconnect() {
        socket.value?.close();
    }

    return {
        connect,
        send,
        disconnect,
        socket,
    };
}

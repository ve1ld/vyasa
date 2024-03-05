class BridgedEventTarget extends EventTarget {}

export const bridged = (eventName) => {
    const customEventTarget = new BridgedEventTarget();

    const sub = (eventHandler) => {
        const EventHandler = (event) => {
            const data = event.detail ;

            eventHandler(data);
        };

        customEventTarget.addEventListener(eventName, EventHandler);

        return () => {
            customEventTarget.removeEventListener(eventName, EventHandler);
        };
    };

    const pub = (data)  => {
        customEventTarget.dispatchEvent(new CustomEvent(eventName, { detail: data }));
    };

    const dispatch = (el, data) => {
        customEventTarget.dispatchEvent(new CustomEvent(eventName, { detail: data }));
        el.pushEventTo(selector, eventName, data);
    }
    const dispatchTo = (el, data, selector) => {
        customEventTarget.dispatchEvent(new CustomEvent(eventName, { detail: data }));
        el.pushEventTo(selector, eventName, data);
    }

    return { sub, pub, dispatch, dispatchTo};
};

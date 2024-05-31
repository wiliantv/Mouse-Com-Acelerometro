package com.wiliantv.mouse;

import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.json.JSONObject;

import java.awt.Robot;
import java.awt.event.InputEvent;
import java.awt.MouseInfo;

public class SensorDataHandler extends TextWebSocketHandler {
    private Robot robot;

    public SensorDataHandler() throws Exception {
        this.robot = new Robot();
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        System.out.println("New connection: " + session.getRemoteAddress());
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        try {
            String payload = message.getPayload();
            JSONObject json = new JSONObject(payload);
            String type = json.getString("type");

            if (type.equals("move")) {
                double dx = json.getDouble("dx");
                double dy = json.getDouble("dy");

                int currentX = MouseInfo.getPointerInfo().getLocation().x;
                int currentY = MouseInfo.getPointerInfo().getLocation().y;

                robot.mouseMove(currentX + (int) dx, currentY + (int) dy);
            } else if (type.equals("click")) {
                String button = json.getString("button");
                if (button.equals("left")) {
                    robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
                    robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
                } else if (button.equals("right")) {
                    robot.mousePress(InputEvent.BUTTON3_DOWN_MASK);
                    robot.mouseRelease(InputEvent.BUTTON3_DOWN_MASK);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        System.out.println("Closed connection: " + session.getRemoteAddress());
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        exception.printStackTrace();
    }
}

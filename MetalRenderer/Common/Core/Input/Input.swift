//
//  Input.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

enum Keyboard
{
    private static var KEY_COUNT: Int = 256
    private static var keys = [Bool].init(repeating: false, count: KEY_COUNT)
    
    static func setKey(_ keyCode: UInt16, isPressed: Bool)
    {
        guard Int(keyCode) < KEY_COUNT else { return }
        
        if keys[Int(keyCode)] != isPressed
        {
            let key = KeyCodes(rawValue: keyCode)!
            
            if isPressed
            {
                keyDownListeners.forEach { $0?(key) }
            }
        }
        
        keys[Int(keyCode)] = isPressed
    }
    
    static func isKeyPressed(_ keyCode: KeyCodes) -> Bool
    {
        guard Int(keyCode.rawValue) < KEY_COUNT else { return false }
        
        return keys[Int(keyCode.rawValue)]
    }
    
    static func reset()
    {
        keys = [Bool].init(repeating: false, count: KEY_COUNT)
    }
    
    typealias KeyListener = (KeyCodes) -> Void
    
    static var onKeyDown: (KeyListener)? {
        willSet {
            keyDownListeners.append(newValue)
        }
    }
    
    private static var keyDownListeners: [KeyListener?] = []
}

enum MouseCodes: Int
{
    case left = 0
    case right = 1
    case center = 2
}

enum Mouse
{
    private static var MOUSE_BUTTON_COUNT = 12
    private static var mouseButtonList = [Bool].init(repeating: false, count: MOUSE_BUTTON_COUNT)
    
    private static var overallMousePosition = float2(0, 0)
    private static var mousePositionDelta = float2(0, 0)
    
    private static var scrollWheelPosition: Float = 0
    private static var lastWheelPosition: Float = 0.0
    private static var scrollWheelChange: Float = 0.0
    
    static var onLeftMouseDown: (() -> Void)?
    static var onLeftMouseUp: (() -> Void)?
    
    static func setMouseButton(_ button: Int, isPressed: Bool)
    {
        if mouseButtonList[button] != isPressed
        {
            if button == 0, isPressed
            {
                onLeftMouseDown?()
            }
            else
            {
                onLeftMouseUp?()
            }
        }
        
        mouseButtonList[button] = isPressed
    }
    
    static func IsMouseButtonPressed(_ button: MouseCodes) -> Bool
    {
        return mouseButtonList[Int(button.rawValue)] == true
    }
    
//    static func setOverallMousePosition(position: float2)
//    {
//        self.overallMousePosition = position
//    }
    
    ///Sets the delta distance the mouse had moved
    static func setMousePositionChange(overallPosition: float2, deltaPosition: float2)
    {
        overallMousePosition = overallPosition
        mousePositionDelta = deltaPosition
    }
    
    static func scrollWheel(_ deltaY: Float)
    {
        scrollWheelPosition += deltaY
        scrollWheelChange += deltaY
    }
    
    //Returns the overall position of the mouse on the current window
    static func getMouseWindowPosition() -> float2
    {
        return overallMousePosition
    }
    
    ///Returns the movement of the wheel since last time getDWheel() was called
    static func getDeltaWheel() -> Float
    {
        let position = scrollWheelChange
        scrollWheelChange = 0
        return position
    }
    
    ///Movement on the y axis since last time getDY() was called.
    static func getDY() -> Float
    {
        let result = mousePositionDelta.y
        mousePositionDelta.y = 0
        return result
    }
    
    ///Movement on the x axis since last time getDX() was called.
    static func getDX() -> Float
    {
        let result = mousePositionDelta.x
        mousePositionDelta.x = 0
        return result
    }
    
    //Returns the mouse position in screen-view coordinates [-1, 1]
    //Left bottom corner: -1
    //Right top corner: 1
    static func getMouseViewportPosition(width: Float, height: Float) -> float2
    {
        //FIXME: брать значение из размеров окна
//        let width = ForwardRenderer.screenSize.x * 0.5
//        let height = ForwardRenderer.screenSize.y * 0.5

        let pointX = overallMousePosition.x
        let pointY = overallMousePosition.y
        
        let x = (2 * pointX / width) - 1
        let y = (2 * -pointY / height) + 1
        
        return float2(x, y)
    }
    
    static func reset()
    {
        mouseButtonList = [Bool].init(repeating: false, count: MOUSE_BUTTON_COUNT)
        mousePositionDelta = .zero
    }
}

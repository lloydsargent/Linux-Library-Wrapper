import CSDL3

@main
struct MyCLI {
    static func main() {
        var deviceRenderer: OpaquePointer? = nil
        var deviceWindow: OpaquePointer? = nil

        SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_VIDEO)

        SDL_CreateWindowAndRenderer("MyName", 400, 300, SDL_WINDOW_MAXIMIZED, &deviceWindow, &deviceRenderer)

        SDL_SetRenderDrawBlendMode(deviceRenderer, SDL_BLENDMODE_BLEND)
        SDL_SetRenderTarget(deviceRenderer, nil)
        SDL_SetRenderDrawColorFloat(deviceRenderer!, 1.0, 1.0, 1.0, 1.0)
        SDL_RenderClear(deviceRenderer)
        SDL_RenderPresent(deviceRenderer)
        
        var quit = false
        while(quit == false) {
            var event: SDL_Event = SDL_Event()

            while (SDL_WaitEventTimeout(&event, 0) != false) {
                if event.type == 0x100 {
                    quit = true
                    break
                }
            }
            SDL_Delay(1)
        }
    }
}

let SDL_WINDOW_MAXIMIZED          : UInt64 = 0x0000000000000080    //**< window is maximized */


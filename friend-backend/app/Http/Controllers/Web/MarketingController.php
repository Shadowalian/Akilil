<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\View\View;

class MarketingController extends Controller
{
    public function home(): View
    {
        return view('marketing.home');
    }

    /**
     * Render a static marketing page. $view comes from the route default
     * in routes/web.php, so it is never user-supplied.
     */
    public function page(string $view): View
    {
        abort_unless(view()->exists("marketing.{$view}"), 404);

        return view("marketing.{$view}");
    }

    public function contact(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:190'],
            'topic' => ['nullable', 'string', 'max:60'],
            'message' => ['required', 'string', 'max:2000'],
        ]);

        // No inbox table yet — the log is the inbox until Task 13 wires
        // this to a real mailbox.
        Log::info('marketing.contact received', $data);

        return redirect()
            ->route('contact')
            ->with('status', "Thank you, {$data['name']}. A person — not a bot — will reply within two working days.");
    }
}

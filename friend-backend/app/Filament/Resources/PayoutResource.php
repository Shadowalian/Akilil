<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PayoutResource\Pages;
use App\Models\Payout;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Auth;

class PayoutResource extends Resource
{
    protected static ?string $model = Payout::class;
    protected static ?string $navigationIcon = 'heroicon-o-credit-card';
    protected static ?string $navigationGroup = 'Finance';
    protected static ?string $navigationLabel = 'Payouts';
    protected static ?int $navigationSort = 11;

    public static function form(Form $form): Form
    {
        return $form->schema([
            \Filament\Forms\Components\TextInput::make('professional.name')->label('Counselor')->disabled(),
            \Filament\Forms\Components\TextInput::make('amount_cents')->disabled(),
            \Filament\Forms\Components\TextInput::make('currency')->disabled(),
            \Filament\Forms\Components\TextInput::make('status')->disabled(),
            \Filament\Forms\Components\TextInput::make('bank_reference')->disabled(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable(),
                Tables\Columns\TextColumn::make('professional.name')->label('Professional')->searchable(),
                Tables\Columns\TextColumn::make('amount_cents')->formatStateUsing(fn ($s, $r) => number_format($s / 100, 2) . ' ' . $r->currency)->alignRight(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state) => match ($state) {
                        'requested' => 'warning',
                        'approved'  => 'info',
                        'sent'      => 'success',
                        'failed'    => 'danger',
                        default     => 'gray',
                    }),
                Tables\Columns\TextColumn::make('bank_reference')->placeholder('—'),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')->options(['requested' => 'Requested', 'approved' => 'Approved', 'sent' => 'Sent', 'failed' => 'Failed']),
            ])
            ->actions([
                Tables\Actions\Action::make('approve')
                    ->icon('heroicon-o-check')
                    ->color('success')
                    ->visible(fn (Payout $r) => $r->status === 'requested')
                    ->action(fn (Payout $record) => $record->update(['status' => 'approved', 'approved_by' => Auth::id(), 'approved_at' => now()])),
                Tables\Actions\Action::make('mark_sent')
                    ->icon('heroicon-o-paper-airplane')
                    ->color('info')
                    ->visible(fn (Payout $r) => $r->status === 'approved')
                    ->form([\Filament\Forms\Components\TextInput::make('bank_reference')->required()])
                    ->action(fn (Payout $record, array $data) => $record->update(['status' => 'sent', 'bank_reference' => $data['bank_reference'], 'sent_at' => now()])),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPayouts::route('/'),
        ];
    }
}